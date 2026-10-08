import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/features_flags.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';
import '../../data/datasources/admin_remote_config_datasource.dart';

/// The console's Remote Config, editable from the phone. The tab lists the
/// categories, one row each; a row opens its own screen with every
/// parameter of that category drawn by its type — a switch for a boolean, a
/// field for a number or a text, and the four states of a feature flag as
/// chips. A change is published at once and the device re-fetches, so what
/// the administrator sees next is what every user gets.
class ConfigTab extends StatefulWidget {
  /// The function by default; a fake in tests.
  final RemoteConfigEditor? source;

  const ConfigTab({super.key, this.source});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  late final _store = _ConfigStore(
    widget.source ?? AdminRemoteConfigDataSource(),
  );

  /// The query lives in the controller, so a reload (which redraws the
  /// list) neither forgets it nor shows a blank box over filtered rows.
  final _search = TextEditingController();
  String get _query => _search.text;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _store.load();
  }

  @override
  void dispose() {
    _search.dispose();
    _store.dispose();
    super.dispose();
  }

  void _open(_Section section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConfigSectionPage(store: _store, section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final params = _store.params;
        if (_store.error != null) {
          return ErrorRetryView(
            error: t.adminConfig.loadFailed,
            onRetry: _store.load,
          );
        }
        if (params == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // A query searches every category at once; the results come
        // grouped under their category's heading. Without one, the tab is
        // the list of categories.
        final List<Widget> body;
        if (_query.trim().isEmpty) {
          body = [
            Text(
              t.adminConfig.intro,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            for (final s in _Section.values)
              if (s.paramsOf(params).isNotEmpty)
                SettingsNavRow(
                  icon: s.icon,
                  label: s.title,
                  hint: t.adminConfig.count(n: s.paramsOf(params).length),
                  onTap: () => _open(s),
                ),
          ];
        } else {
          body = [
            for (final s in _Section.values)
              if (_ConfigStore.search(s.paramsOf(params), _query)
                  case final hits when hits.isNotEmpty) ...[
                ClaySectionHeader(title: s.title, underline: true),
                for (final p in hits) _row(context, p),
              ],
          ];
          if (body.isEmpty) {
            body.add(
              ClayEmptyState(
                icon: Icons.search_off_rounded,
                message: t.adminConfig.noResults(query: _query.trim()),
              ),
            );
          }
        }
        return RefreshIndicator(
          onRefresh: _store.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.md,
              AppSpacing.marginMobile,
              AppSpacing.xl,
            ),
            itemCount: body.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => index == 0
                ? _SearchField(
                    controller: _search,
                    hint: t.adminConfig.searchAll,
                  )
                : body[index - 1],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, RemoteParam p) => _ParamRow(
    param: p,
    label: _ConfigStore.label(p.name),
    saving: _store.saving == p.name,
    onChanged: (v) => _publish(context, _store, p, v),
  );
}

/// Publishes one value and tells the administrator how it went.
Future<void> _publish(
  BuildContext context,
  _ConfigStore store,
  RemoteParam param,
  String value,
) async {
  final ok = await store.set(param, value);
  if (!context.mounted) return;
  if (ok) {
    AppDialog.success(
      message: t.adminConfig.saved(name: _ConfigStore.label(param.name)),
    ).notify(context);
  } else {
    AppDialog.error(message: t.adminConfig.saveFailed).show(context);
  }
}

/// The search box above a list, in the shape of the other admin tabs'.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SearchField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: t.adminConfig.clearSearch,
                  onPressed: controller.clear,
                ),
          isDense: true,
        ),
      ),
    );
  }
}

/// One category's screen: its parameters, each with a heading, the
/// console's description and the control for its type. Its search box
/// looks only inside this category.
class _ConfigSectionPage extends StatefulWidget {
  final _ConfigStore store;
  final _Section section;

  const _ConfigSectionPage({required this.store, required this.section});

  @override
  State<_ConfigSectionPage> createState() => _ConfigSectionPageState();
}

class _ConfigSectionPageState extends State<_ConfigSectionPage> {
  final _search = TextEditingController();
  String get _query => _search.text;

  /// Features only: show the flags in one state (0–3), or all of them.
  String? _flagFilter;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final section = widget.section;
    final filters = section == _Section.features;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: section.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final rows = [
              for (final p in _ConfigStore.search(
                section.paramsOf(store.params ?? const []),
                _query,
              ))
                if (_flagFilter == null || p.value == _flagFilter) p,
            ];
            final head = filters ? 2 : 1;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.md,
                AppSpacing.marginMobile,
                AppSpacing.xl,
              ),
              itemCount: rows.length + head + (rows.isEmpty ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SearchField(
                    controller: _search,
                    hint: t.adminConfig.searchIn(section: section.title),
                  );
                }
                if (filters && index == 1) {
                  return _FlagFilter(
                    value: _flagFilter,
                    onChanged: (v) => setState(() => _flagFilter = v),
                  );
                }
                if (rows.isEmpty) {
                  return ClayEmptyState(
                    icon: Icons.search_off_rounded,
                    message: _query.trim().isEmpty
                        ? t.adminConfig.noFlagsInState
                        : t.adminConfig.noResults(query: _query.trim()),
                  );
                }
                final p = rows[index - head];
                return _ParamRow(
                  param: p,
                  label: _ConfigStore.label(p.name),
                  saving: store.saving == p.name,
                  onChanged: (v) => _publish(context, store, p, v),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The categories, in the order the tab lists them. Membership is by the
/// parameter's key prefix, so a new console parameter lands somewhere
/// sensible without a code change.
enum _Section {
  features(Icons.flag_rounded),
  adsQuotas(Icons.campaign_rounded),
  sharing(Icons.share_rounded),
  voice(Icons.record_voice_over_rounded),
  versions(Icons.system_update_rounded),
  gemini(Icons.dns_rounded),
  other(Icons.more_horiz_rounded)
  ;

  final IconData icon;
  const _Section(this.icon);

  String get title => switch (this) {
    features => t.adminConfig.groups.features,
    adsQuotas => t.adminConfig.groups.adsQuotas,
    sharing => t.adminConfig.groups.sharing,
    voice => t.adminConfig.groups.voice,
    versions => t.adminConfig.groups.versions,
    gemini => t.adminConfig.groups.gemini,
    other => t.adminConfig.groups.other,
  };

  static const _versionKeys = {
    'isProd',
    'minimumVersion',
    'latestVersion',
    'iosAppStoreId',
  };

  static _Section of(RemoteParam p) {
    final n = p.name;
    if (n.startsWith('ff_')) return features;
    if (n.startsWith('ads_') || n.startsWith('quota_')) return adsQuotas;
    if (n.startsWith('share_free_')) return sharing;
    if (n.startsWith('tts_')) return voice;
    if (n.startsWith('gemini_')) return gemini;
    if (_versionKeys.contains(n)) return versions;
    return other;
  }

  List<RemoteParam> paramsOf(List<RemoteParam> all) => [
    for (final p in all)
      if (of(p) == this) p,
  ];
}

/// The template as loaded, shared by the tab and the category screens so a
/// value published on one is what the other shows.
class _ConfigStore extends ChangeNotifier {
  final RemoteConfigEditor editor;
  List<RemoteParam>? params;
  Object? error;

  /// The parameter being published right now, for its row's spinner.
  String? saving;

  _ConfigStore(this.editor);

  Future<void> load() async {
    error = null;
    params = null;
    notifyListeners();
    try {
      params = await editor.fetch();
    } catch (e) {
      error = e;
    }
    notifyListeners();
  }

  /// Publishes one value; true when the console took it.
  Future<bool> set(RemoteParam param, String value) async {
    if (value == param.value || saving != null) return false;
    saving = param.name;
    notifyListeners();
    try {
      params = await editor.set(param.name, value);
      // The device itself: the live stream brings the change in a moment,
      // the fetch brings it now.
      FirebaseService().refreshRemoteConfig();
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = null;
      notifyListeners();
    }
  }

  /// The parameters whose heading, key, description or value carries
  /// [query] (case-insensitive); all of them for a blank query.
  static List<RemoteParam> search(List<RemoteParam> params, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return params;
    return [
      for (final p in params)
        if (label(p.name).toLowerCase().contains(q) ||
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.value.toLowerCase().contains(q))
          p,
    ];
  }

  /// The short heading for a parameter: a feature flag is named as the app
  /// names it everywhere else, the rest come from the labels table, and a
  /// key nobody wrote a label for shows as itself.
  static String label(String name) {
    for (final f in FeaturesFlags.values) {
      if (f.key == name) return f.label;
    }
    return switch (t['adminConfig.labels.$name']) {
      final String text => text,
      _ => name,
    };
  }
}

class _ParamRow extends StatelessWidget {
  final RemoteParam param;
  final String label;
  final bool saving;
  final ValueChanged<String> onChanged;

  const _ParamRow({
    required this.param,
    required this.label,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Widget control;
    if (param.isFeatureFlag) {
      control = _FlagChips(value: param.value, onChanged: onChanged);
    } else if (param.isBoolean) {
      control = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Switch.adaptive(
          value: param.value == 'true',
          onChanged: saving ? null : (v) => onChanged(v ? 'true' : 'false'),
        ),
      );
    } else {
      control = _ValueField(
        value: param.value,
        numeric: param.isNumber,
        enabled: !saving,
        onSubmit: onChanged,
      );
    }
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyLg)),
              if (saving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  param.name,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
            ],
          ),
          if (param.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              param.description,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          control,
        ],
      ),
    );
  }
}

/// The four states of a flag: code, label, icon.
List<(String, String, IconData)> _flagOptions() {
  final f = t.adminConfig.flag;
  return [
    ('0', f.hidden, Icons.visibility_off_rounded),
    ('1', f.comingSoon, Icons.schedule_rounded),
    ('2', f.everyone, Icons.public_rounded),
    ('3', f.premium, Icons.workspace_premium_rounded),
  ];
}

/// Narrows the features screen to the flags in one state; "all" lifts it.
class _FlagFilter extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FlagFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (null, t.adminConfig.filterAll, Icons.filter_list_rounded),
      ..._flagOptions(),
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (code, label, icon) in options)
          _FlagChip(
            label: label,
            icon: icon,
            selected: value == code,
            onTap: () => onChanged(code),
          ),
      ],
    );
  }
}

/// The four states of a feature flag, one chip each, the current one lit.
class _FlagChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FlagChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = _flagOptions();
    // All four on one row, equal widths: the labels are short and the
    // chip is tight, and a label that still does not fit shrinks rather
    // than wrapping to a second row.
    return Row(
      children: [
        for (final (i, (code, label, icon)) in options.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _FlagChip(
              label: label,
              icon: icon,
              selected: value == code,
              onTap: () => onChanged(code),
            ),
          ),
        ],
      ],
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FlagChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.primary;
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A number or a text, committed with the save button or the keyboard's
/// done key, never on every keystroke.
class _ValueField extends StatefulWidget {
  final String value;
  final bool numeric;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  const _ValueField({
    required this.value,
    required this.numeric,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _ValueField old) {
    super.didUpdateWidget(old);
    // A value published from here (or elsewhere) replaces the draft.
    if (old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _controller.text.trim();
    if (v != widget.value) widget.onSubmit(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClayInset(
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              keyboardType: widget.numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: AppTextStyles.bodyMd,
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => ClayIconButton(
            icon: Icons.check_rounded,
            filled: true,
            size: 44,
            tooltip: t.common.save,
            onTap: widget.enabled && value.text.trim() != widget.value
                ? _submit
                : null,
          ),
        ),
      ],
    );
  }
}
