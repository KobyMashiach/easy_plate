import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../errors/app_exception.dart';
import '../network/image_search_client.dart';
import '../services/image_storage_service.dart';
import '../utils/i18n/strings.g.dart';
import 'app_dialog.dart';
import 'clay/clay.dart';

/// Google image results for [query], ten at a time, more as the grid
/// scrolls. Resolves with the stored file name of the picture picked, or
/// null when the user backed out.
Future<String?> pickWebImage(BuildContext context, {required String query}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => WebImagePickerPage(initialQuery: query),
    ),
  );
}

class WebImagePickerPage extends StatefulWidget {
  final String initialQuery;
  final ImageSearchClient? client;

  const WebImagePickerPage({
    super.key,
    required this.initialQuery,
    this.client,
  });

  @override
  State<WebImagePickerPage> createState() => _WebImagePickerPageState();
}

class _WebImagePickerPageState extends State<WebImagePickerPage> {
  static const _uuid = Uuid();

  late final ImageSearchClient _client = widget.client ?? ImageSearchClient();
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );
  final _scroll = ScrollController();

  final List<WebImageResult> _results = [];
  int? _nextStart = 1;
  bool _loading = false;
  bool _unavailable = false;
  String? _error;

  /// Which search the results on screen belong to; a reply from an older
  /// search is dropped rather than mixed in.
  int _generation = 0;
  String _searched = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  /// Within two rows of the end: the next ten are asked for before the
  /// user reaches the last picture, so the grid never visibly stops.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining < 400) _loadMore();
  }

  void _search() {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _generation++;
      _searched = query;
      _results.clear();
      _nextStart = 1;
      _error = null;
      // A request still in flight belongs to the old generation: its reply
      // is dropped, and so must its loading flag be, or nothing loads again.
      _loading = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    final start = _nextStart;
    if (_loading || start == null || _unavailable) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _client.search(_searched, start: start);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results.addAll(page.items);
        _nextStart = page.nextStart;
      });
    } on AppException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (isImageSearchUnavailable(e)) {
          _unavailable = true;
        } else {
          _error = e.type == AppErrorType.networkError
              ? t.common.networkError
              : t.image.webSearchFailed;
        }
      });
    } catch (e) {
      debugPrint('Image search failed: $e');
      if (!mounted || generation != _generation) return;
      setState(() => _error = t.image.webSearchFailed);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  /// The picture is fetched and stored like one taken here, so from then
  /// on nothing downstream knows it came from the web.
  Future<void> _pick(WebImageResult result) async {
    final fileName = await AppDialog.busy(context, () async {
      final bytes = await _client.download(result);
      if (bytes == null) return null;
      final name = '${_uuid.v4()}.jpg';
      final stored = await ImageStorageService().storeBytes(name, bytes);
      return stored == null ? null : name;
    });
    if (!mounted) return;
    if (fileName == null) {
      AppDialog.error(message: t.image.webSearchDownloadFailed).show(context);
      return;
    }
    Navigator.of(context).pop(fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.image.webSearchTitle,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.gutter,
              AppSpacing.marginMobile,
              AppSpacing.base,
            ),
            child: ClayInset(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.outline),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      style: AppTextStyles.bodyMd,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: t.image.webSearchHint,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.gutter,
                        ),
                      ),
                    ),
                  ),
                  ClayIconButton(
                    icon: Icons.arrow_forward_rounded,
                    size: 40,
                    tooltip: t.common.search,
                    onTap: _search,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_unavailable) return _Notice(text: t.image.webSearchUnavailable);
    if (_results.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error case final error?) {
        return _Notice(text: error, onRetry: _loadMore);
      }
      return _Notice(text: t.image.webSearchEmpty);
    }
    // One extra cell at the end: the spinner while the next ten load, the
    // error with a retry, or a line saying that was all of them.
    final tail = _loading || _error != null || _nextStart == null;
    return GridView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.base,
        AppSpacing.marginMobile,
        MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: _results.length + (tail ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) return _tailCell();
        final result = _results[index];
        return _ResultTile(result: result, onTap: () => _pick(result));
      },
    );
  }

  Widget _tailCell() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: ClayButton(
          label: t.common.retry,
          icon: Icons.refresh_rounded,
          onPressed: _loadMore,
        ),
      );
    }
    return Center(
      child: Text(
        t.image.webSearchEnd,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final WebImageResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The thumbnail is Google's own copy: small, fast, and there
            // even when the site behind it is slow. The full picture is
            // fetched only for the one that is picked.
            Image.network(
              result.thumbnail,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(color: AppColors.surfaceContainerLow),
              errorBuilder: (context, error, stack) => Container(
                color: AppColors.surfaceContainerLow,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.outline,
                ),
              ),
            ),
            if (result.source.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.xs,
                  ),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Text(
                    result.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _Notice({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: t.common.retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
