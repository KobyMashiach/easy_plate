import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/daily_quota_policy.dart';
import '../../../../core/monetization/daily_usage_service.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/store_review_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/allergen_chip_selector.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/landscape_hint.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../../core/widgets/pop_if_current.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../../my_recipes/presentation/widgets/ingredient_section_heading.dart';
import '../../../recipe_books/presentation/widgets/add_to_book_prompt.dart';
import '../../../assistant/presentation/assistant_voice.dart';
import '../../data/datasources/recent_inputs_store.dart';
import '../../data/recipe_image_shrinker.dart';
import '../../domain/channel_detector.dart';
import '../../domain/entities/ingestion_file.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/recipe_image_candidate.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/usecases/build_template_recipe.dart';
import '../bloc/ingestion_bloc.dart';
import '../widgets/suggestion_request_sheet.dart';
import 'bulk_import_page.dart' show BulkImportEntry;
import '../widgets/ai_quota_indicator.dart';
import '../widgets/video_image_picker.dart';
import '../../../../core/widgets/recipe_source_link.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/services/share_intent_service.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/features/feature_gate.dart';

/// The channels whose submit is an AI call — text read, a link fetched, a
/// video watched, a recording listened to, a recipe written — the ones
/// behind the daily quota. A hand-written recipe is not, and a web search
/// pays when a result is opened, not when the search runs.
bool _isAiExtraction(RecipeIngestionChannel channel) =>
    channel == RecipeIngestionChannel.rawText ||
    channel == RecipeIngestionChannel.urlScrape ||
    channel == RecipeIngestionChannel.socialVideo ||
    channel == RecipeIngestionChannel.file ||
    channel == RecipeIngestionChannel.aiRequest;

/// Every channel that ends in an AI call shows the day's allowance — the web
/// search too, since opening one of its results spends from it.
bool _showsAiQuota(RecipeIngestionChannel channel) =>
    channel != RecipeIngestionChannel.manual;

/// Starts a link extraction once the quota gate has let it through. Every
/// path that hands a URL to the model goes through here, so the gate can never
/// be walked around by a second button.
Future<void> _extractUrl(BuildContext context, String url) async {
  final bloc = context.read<IngestionBloc>();
  if (!await QuotaGates.extractWithAi(context)) return;
  bloc.add(IngestionEvent.parseUrl(url));
}

String _channelLabel(RecipeIngestionChannel channel) => switch (channel) {
  RecipeIngestionChannel.rawText => t.ingestion.pasteText,
  RecipeIngestionChannel.webSearch => t.ingestion.webSearch,
  RecipeIngestionChannel.urlScrape => t.ingestion.urlScrape,
  RecipeIngestionChannel.socialVideo => t.ingestion.socialVideo,
  RecipeIngestionChannel.aiRequest => t.ingestion.aiRequest,
  RecipeIngestionChannel.manual => t.ingestion.manual,
  RecipeIngestionChannel.file =>
    _photosAllowed ? t.ingestion.filePhoto : t.ingestion.file,
};

/// Whether the file channel takes photos too (a cookbook page, a
/// screenshot, handwriting). With the switch off it is the recording / PDF
/// channel it always was, copy and all.
bool get _photosAllowed => FeaturesFlags.ingestPhoto.isEnabled;

/// What each channel does, in a few sentences: what to give it, what the
/// app does with it, and what it costs. Shown on the channel's card, so the
/// choice never has to be guessed from a chip's two words.
String _channelDescription(RecipeIngestionChannel channel) => switch (channel) {
  RecipeIngestionChannel.rawText => t.ingestion.pasteTextDescription,
  RecipeIngestionChannel.webSearch => t.ingestion.webSearchDescription,
  RecipeIngestionChannel.urlScrape => t.ingestion.urlScrapeDescription,
  RecipeIngestionChannel.socialVideo => t.ingestion.socialVideoDescription,
  RecipeIngestionChannel.aiRequest => t.ingestion.aiRequestDescription,
  RecipeIngestionChannel.manual => t.ingestion.manualDescription,
  RecipeIngestionChannel.file =>
    _photosAllowed
        ? t.ingestion.filePhotoDescription
        : t.ingestion.fileDescription,
};

/// The console switch for each way in. Manual entry has none: an editor
/// with nothing in it is the floor the others stand on.
FeaturesFlags? channelFeature(RecipeIngestionChannel channel) =>
    switch (channel) {
      RecipeIngestionChannel.rawText => FeaturesFlags.ingestText,
      RecipeIngestionChannel.webSearch => FeaturesFlags.ingestWebSearch,
      RecipeIngestionChannel.urlScrape => FeaturesFlags.ingestLink,
      RecipeIngestionChannel.socialVideo => FeaturesFlags.ingestSocialVideo,
      RecipeIngestionChannel.aiRequest => FeaturesFlags.ingestAiRequest,
      RecipeIngestionChannel.file => FeaturesFlags.ingestFile,
      RecipeIngestionChannel.manual => null,
    };

bool _channelAllowed(RecipeIngestionChannel channel) {
  final feature = channelFeature(channel);
  return feature == null || feature.isEnabled;
}

/// The channel the text points to, moved to the nearest one the console
/// allows: a video link falls back to reading the page, a request and a
/// search stand in for each other, and pasted text is the floor. Null when
/// none of them is allowed — the screen then stays where it is.
RecipeIngestionChannel? autoChannelFor(String text) {
  const c = RecipeIngestionChannel.values;
  final detected = ChannelDetector.detect(text);
  final chain = switch (detected) {
    RecipeIngestionChannel.socialVideo => [c[3], c[2]],
    RecipeIngestionChannel.urlScrape => [c[2]],
    RecipeIngestionChannel.aiRequest => [c[4], c[1], c[0]],
    RecipeIngestionChannel.webSearch => [c[1], c[4], c[0]],
    _ => [c[0], c[4]],
  };
  return chain.where(_channelAllowed).firstOrNull;
}

/// The channels the text box serves (the others have their own controls).
bool _hasTextField(RecipeIngestionChannel channel) =>
    channel != RecipeIngestionChannel.manual &&
    channel != RecipeIngestionChannel.file;

IconData _channelIcon(RecipeIngestionChannel channel) => switch (channel) {
  RecipeIngestionChannel.rawText => Icons.content_paste_rounded,
  RecipeIngestionChannel.webSearch => Icons.travel_explore_rounded,
  RecipeIngestionChannel.urlScrape => Icons.link_rounded,
  RecipeIngestionChannel.socialVideo => Icons.play_circle_rounded,
  RecipeIngestionChannel.aiRequest => Icons.auto_awesome_rounded,
  RecipeIngestionChannel.manual => Icons.edit_note_rounded,
  RecipeIngestionChannel.file =>
    _photosAllowed ? Icons.perm_media_rounded : Icons.mic_rounded,
};

class IngestionPage extends StatelessWidget {
  /// What the screen opens on when something was shared in — a channel, a
  /// text, a file. Null opens on the default channel, empty.
  final IngestionLaunch? launch;

  const IngestionPage({super.key, this.launch});

  @override
  Widget build(BuildContext context) {
    // Opened empty, or on a shared piece of text, the screen picks the
    // category itself from the text; opened on a set channel (Shefi, a
    // shared file) it keeps that one.
    final launch = this.launch;
    final auto =
        FeaturesFlags.ingestAutoChannel.isEnabled &&
        (launch == null || (launch.text != null && launch.files.isEmpty));
    final fixed = launch?.channel ?? RecipeIngestionChannel.rawText;
    final initialChannel = auto
        ? autoChannelFor(
                launch?.text ??
                    Walkthrough.prefill(t.walkthrough.demo.recipeText) ??
                    '',
              ) ??
              fixed
        : fixed;
    return BlocProvider(
      create: (context) => IngestionBloc.fromContext(
        context,
        initialChannel: initialChannel,
        autoChannel: auto,
      ),
      child: BlocConsumer<IngestionBloc, IngestionState>(
        listener: (context, state) {
          final notice = switch (state) {
            IngestionReview(:final notice) => notice,
            IngestionUnparsed(:final notice) => notice,
            _ => null,
          };
          if (notice != null) {
            AppDialog.error(message: notice).notify(context);
          }
          final savedId = context.read<IngestionBloc>().lastSavedRecipeId;
          if (state case IngestionSearchResults(justSaved: true)) {
            AppDialog.success(
              message: t.ingestion.savedFromList,
            ).notify(context);
            unawaited(() async {
              if (savedId != null) await offerAddToBook(context, savedId);
              unawaited(StoreReviewService().onSuccessMoment());
            }());
          }
          if (state is IngestionSaved) {
            unawaited(() async {
              // Offered before the screen closes: the sheet needs this
              // screen's providers, and the spinner stays up behind it.
              if (savedId != null) await offerAddToBook(context, savedId);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              // After the pop so the store's sheet lands on the recipes list.
              unawaited(StoreReviewService().onSuccessMoment());
            }());
          }
        },
        builder: (context, state) {
          final bloc = context.read<IngestionBloc>();
          // Out of a result opened from a list, back is the list: the search
          // (or the suggestions) was already paid for.
          final toResults = bloc.canReturnToResults;
          return PopScope(
            canPop: !toResults,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && toResults) {
                bloc.add(const IngestionEvent.backToResults());
              }
            },
            child: ClayScaffold(
              appBar: ClayTopAppBar(
                title: t.ingestion.title,
                leadingIcon: Icons.arrow_back_rounded,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
              body: SafeArea(
                child: switch (state) {
                  IngestionIdle(channel: final channel) => _ChannelForm(
                    channel: channel,
                    // A link that came in with the screen counts as pasted —
                    // once: a draft is what a failed run left behind, and
                    // running it again on its own would spend another try.
                    autoRunInitial:
                        context.read<IngestionBloc>().draftText(channel) ==
                            null &&
                        launch?.text != null,
                    // What this channel last submitted comes back after a
                    // failure; otherwise only the channel it was shared to
                    // starts filled in.
                    initialText:
                        context.read<IngestionBloc>().draftText(channel) ??
                        (launch?.channel == channel ||
                                context.read<IngestionBloc>().autoChannel
                            ? launch?.text
                            : null),
                    initialFiles: switch (context
                        .read<IngestionBloc>()
                        .draftFiles) {
                      final files
                          when files.isNotEmpty &&
                              channel == RecipeIngestionChannel.file =>
                        files,
                      _ =>
                        launch?.channel == channel
                            ? launch?.files ?? const []
                            : const [],
                    },
                  ),
                  IngestionParsing(channel: final channel, work: final work) =>
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.gutter),
                          Text(
                            switch (work) {
                              IngestionWork.searching => t.ingestion.searching,
                              IngestionWork.suggesting =>
                                t.ingestion.suggesting,
                              IngestionWork.loadingPage =>
                                t.ingestion.loadingOriginal,
                              IngestionWork.analyzing
                                  when channel ==
                                      RecipeIngestionChannel.aiRequest =>
                                t.ingestion.generating,
                              IngestionWork.analyzing => t.ingestion.parsing,
                            },
                            style: AppTextStyles.bodyMd,
                          ),
                        ],
                      ),
                    ),
                  IngestionSearchResults(
                    results: final results,
                    suggested: final suggested,
                    savedUrls: final savedUrls,
                  ) =>
                    _SearchResults(
                      results: results,
                      suggested: suggested,
                      savedUrls: savedUrls,
                    ),
                  IngestionReview(
                    recipe: final recipe,
                    imageCandidates: final imageCandidates,
                    selectedImage: final selectedImage,
                  ) =>
                    _ReviewRecipe(
                      recipe: recipe,
                      imageCandidates: imageCandidates,
                      selectedImage: selectedImage,
                    ),
                  IngestionOriginal(page: final page) => _OriginalView(
                    page: page,
                  ),
                  IngestionError(channel: final channel, error: final error) =>
                    _ErrorView(channel: channel, error: error),
                  IngestionUnparsed(
                    channel: final channel,
                    text: final text,
                    sourceUrl: final sourceUrl,
                    timedOut: final timedOut,
                    retryable: final retryable,
                  ) =>
                    _UnparsedView(
                      channel: channel,
                      text: text,
                      sourceUrl: sourceUrl,
                      timedOut: timedOut,
                      retryable: retryable,
                    ),
                  IngestionSaved() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelForm extends StatefulWidget {
  final RecipeIngestionChannel channel;
  final String? initialText;
  final List<IngestionFile> initialFiles;
  final bool autoRunInitial;

  const _ChannelForm({
    required this.channel,
    this.autoRunInitial = false,
    this.initialText,
    this.initialFiles = const [],
  });

  @override
  State<_ChannelForm> createState() => _ChannelFormState();
}

class _ChannelFormState extends State<_ChannelForm> {
  // The tour opens on the pasted-text channel with a sample recipe already
  // in the box, so the reader sees what the model is given without typing.
  // The form is the same widget on every channel, so the text carries over.
  late final _controller = TextEditingController(
    text:
        widget.initialText ??
        (widget.channel == RecipeIngestionChannel.rawText
            ? Walkthrough.prefill(t.walkthrough.demo.recipeText)
            : null),
  );

  /// The recordings and PDFs chosen — or shared in — for the file channel,
  /// in the order they arrived: together they are one recipe.
  late final List<IngestionFile> _files = [...widget.initialFiles];
  bool _picking = false;

  /// Drives the button's enabled state. A tap on an empty form used to fall
  /// through [_submit]'s guard and do nothing, which reads as a broken button
  /// rather than a missing input.
  late bool _hasInput = _controller.text.trim().isNotEmpty;

  /// The chip whose explanation is open under the row — the last one
  /// tapped; null until a chip is tapped, or after it is tapped again.
  RecipeIngestionChannel? _explained;

  /// Whether the category is still the app's pick (see
  /// [IngestionBloc.autoChannel]) and the console lets it pick.
  bool get _auto =>
      context.read<IngestionBloc>().autoChannel &&
      FeaturesFlags.ingestAutoChannel.isEnabled;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncHasInput);
    _controller.addListener(_detectChannel);
    _controller.addListener(_watchForPaste);
    if (FeaturesFlags.ingestRecent.isEnabled) {
      RecentInputsStore.instance.read().then((recent) {
        if (mounted) setState(() => _recent = recent);
      });
    }
    final bloc = context.read<IngestionBloc>();
    if (widget.autoRunInitial && !bloc.initialAutoRunUsed) {
      bloc.initialAutoRunUsed = true;
      _previousText = '';
      // After the first frame, so the category picked from it is in place.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _watchForPaste();
      });
    }
    // While this form is up, a share from another app lands here rather
    // than opening a second screen: the user went back to WhatsApp for the
    // next voice note of the same recipe.
    ShareIntentService().formOpened();
    ShareIntentService().latest.addListener(_onShared);
  }

  void _onShared() {
    final service = ShareIntentService();
    final launch = service.latest.value;
    if (launch == null || !mounted) return;
    service.clear();
    final bloc = context.read<IngestionBloc>();
    if (launch.files.isNotEmpty) {
      if (IngestionFile.tooLarge([..._files, ...launch.files])) {
        AppDialog.warning(message: t.ingestion.fileTooLarge).notify(context);
        return;
      }
      setState(() => _files.addAll(launch.files));
      if (widget.channel != RecipeIngestionChannel.file) {
        bloc.add(const .selectChannel(RecipeIngestionChannel.file));
      }
      return;
    }
    if (launch.text case final text?) {
      // A recipe sent over WhatsApp in several messages arrives as several
      // shares: each one after the first is added under what is already
      // in the box. A link replaces, never joins — two links are not one.
      final current = _controller.text.trim();
      final append =
          current.isNotEmpty &&
          current != text.trim() &&
          _hasTextField(widget.channel) &&
          !IngestionLaunch.isWebUrl(current) &&
          !IngestionLaunch.isWebUrl(text);
      _controller.text = append ? '$current\n\n${text.trim()}' : text;
      if (append) {
        AppDialog.info(message: t.ingestion.sharedAppended).notify(context);
      }
      // In auto mode the text listener has already picked the category.
      if (_auto) return;
      final channel = launch.channel ?? RecipeIngestionChannel.rawText;
      if (widget.channel != channel) bloc.add(.selectChannel(channel));
    }
  }

  // ---- A pasted link runs on its own --------------------------------------

  /// The text as the last change left it, to tell a paste (empty → a whole
  /// link in one change) from typing.
  late String _previousText = _controller.text.trim();
  Timer? _autoRunTimer;

  /// Seconds left before a pasted link runs; 0 when nothing is counting.
  int _autoRunLeft = 0;

  void _watchForPaste() {
    final text = _controller.text.trim();
    final previous = _previousText;
    _previousText = text;
    // The listener also fires on cursor moves.
    if (text == previous) return;
    _cancelAutoRun();
    if (previous.isEmpty && IngestionLaunch.isWebUrl(text)) _startAutoRun();
  }

  /// Only when it costs nothing more than the run itself: an extraction is
  /// left without a video, or the day is not counted at all.
  bool get _freeToRun =>
      !MonetizationConfig.aiGated ||
      DailyQuotaPolicy.aiExtraction(
            usedToday: DailyUsageService().aiExtractionsToday,
            premium: MonetizationConfig.isPremium,
            limits: MonetizationConfig.limits,
          ) ==
          GateVerdict.free;

  void _startAutoRun() {
    if (!FeaturesFlags.ingestPasteAutoRun.isEnabled || !_freeToRun) return;
    setState(() => _autoRunLeft = 2);
    _autoRunTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_autoRunLeft > 1) return setState(() => _autoRunLeft--);
      timer.cancel();
      _autoRunTimer = null;
      setState(() => _autoRunLeft = 0);
      // By now the category follows the link; one the user set to a search
      // or a request is theirs, and a link there is not run.
      if (widget.channel == RecipeIngestionChannel.urlScrape ||
          widget.channel == RecipeIngestionChannel.socialVideo) {
        _once(_submit);
      }
    });
  }

  void _cancelAutoRun() {
    _autoRunTimer?.cancel();
    _autoRunTimer = null;
    if (_autoRunLeft != 0 && mounted) setState(() => _autoRunLeft = 0);
  }

  // ---- Recent inputs ------------------------------------------------------

  List<RecentInput> _recent = const [];

  void _useRecent(RecentInput recent) {
    _controller.value = TextEditingValue(
      text: recent.text,
      selection: TextSelection.collapsed(offset: recent.text.length),
    );
    // It goes back in as what it was sent as, even where the app would
    // have guessed otherwise.
    if (widget.channel != recent.channel && _channelAllowed(recent.channel)) {
      final bloc = context.read<IngestionBloc>();
      bloc.autoChannel = false;
      bloc.add(.selectChannel(recent.channel));
    }
  }

  Future<void> _removeRecent(RecentInput recent) async {
    final next = await RecentInputsStore.instance.remove(recent.text);
    if (mounted) setState(() => _recent = next);
  }

  // ---- Voice --------------------------------------------------------------

  /// Shefi's recognizer — the device's own, in the app's language. Made on
  /// the first tap, so the screen opens without touching the microphone.
  AssistantVoice? _voice;

  Future<void> _toggleVoice() async {
    if (!guardFeature(context, FeaturesFlags.ingestVoice)) return;
    final voice = _voice ??= AssistantVoice();
    if (voice.listening.value) return voice.stopListening();
    setState(() {});
    _cancelAutoRun();
    final base = _controller.text.trimRight();
    final ok = await voice.listen((words, {required isFinal}) {
      if (!mounted) return;
      final joined = base.isEmpty ? words : '$base $words';
      _controller.value = TextEditingValue(
        text: joined,
        selection: TextSelection.collapsed(offset: joined.length),
      );
    });
    if (!ok && mounted) {
      AppDialog.warning(message: t.ingestion.voiceUnavailable).notify(context);
    }
  }

  /// Moves the category to what the text now looks like, while it is still
  /// the app's to choose.
  void _detectChannel() {
    if (!_auto || !_hasTextField(widget.channel)) return;
    final next = autoChannelFor(_controller.text);
    if (next != null && next != widget.channel) {
      context.read<IngestionBloc>().add(.selectChannel(next));
    }
  }

  /// A tap on a chip is the user's choice: the app stops picking for the
  /// rest of this screen, and the chip's explanation opens (a second tap on
  /// the same chip closes it).
  void _pickChannel(RecipeIngestionChannel channel) {
    _cancelAutoRun();
    final bloc = context.read<IngestionBloc>();
    bloc.autoChannel = false;
    setState(
      () => _explained = _explained == channel && widget.channel == channel
          ? null
          : channel,
    );
    if (channel != widget.channel) bloc.add(.selectChannel(channel));
  }

  void _syncHasInput() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
  }

  @override
  void dispose() {
    ShareIntentService().latest.removeListener(_onShared);
    ShareIntentService().formClosed();
    _controller.removeListener(_syncHasInput);
    _controller.removeListener(_detectChannel);
    _controller.removeListener(_watchForPaste);
    _autoRunTimer?.cancel();
    unawaited(_voice?.dispose());
    _controller.dispose();
    super.dispose();
  }

  String get _hint => _auto ? t.ingestion.autoHint : _channelHint;

  String get _channelHint => switch (widget.channel) {
    RecipeIngestionChannel.rawText => t.ingestion.pasteHint,
    RecipeIngestionChannel.webSearch => t.ingestion.webSearchHint,
    RecipeIngestionChannel.urlScrape => t.ingestion.urlScrapeHint,
    RecipeIngestionChannel.socialVideo => t.ingestion.socialVideoHint,
    RecipeIngestionChannel.aiRequest => t.ingestion.aiRequestHint,
    // No text input on these channels: the editor, or a picked file, is
    // the form.
    RecipeIngestionChannel.manual || RecipeIngestionChannel.file => '',
  };

  /// The most characters a channel's text field sends. The proxy's own
  /// limit is the 16 MB request body (functions/aiProxy.js MAX_BODY_BYTES),
  /// which a paste never reaches; these are the sizes past which the model
  /// is being handed a whole site, not a recipe — and the daily extraction
  /// would be spent on it. A shared-in text lands in the field whole, so
  /// the submit checks too, not only the field.
  static int maxCharsFor(RecipeIngestionChannel channel) => switch (channel) {
    RecipeIngestionChannel.rawText => 30000,
    RecipeIngestionChannel.aiRequest => 2000,
    RecipeIngestionChannel.webSearch => 300,
    RecipeIngestionChannel.urlScrape ||
    RecipeIngestionChannel.socialVideo => 2048,
    // No text field on these channels: -1 is the formatter's "no limit".
    RecipeIngestionChannel.manual || RecipeIngestionChannel.file => -1,
  };

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<IngestionBloc>();
    final max = maxCharsFor(widget.channel);
    if (max > 0 && text.length > max) {
      AppDialog.warning(
        message: t.ingestion.textTooLong(max: max),
      ).notify(context);
      return;
    }
    // A link that is not one is refused here, before the gate below spends
    // an extraction on it. A link inside a caption (a WhatsApp share, "look
    // at this https://…") is taken out of it.
    var value = text;
    if (widget.channel == RecipeIngestionChannel.urlScrape ||
        widget.channel == RecipeIngestionChannel.socialVideo) {
      final url = IngestionLaunch.findWebUrl(text);
      if (url == null) {
        AppDialog.warning(message: t.ingestion.invalidUrl).notify(context);
        return;
      }
      value = url;
    }
    // The AI channels cost a daily extraction, and a video: asked for
    // before the model is touched, so a refused gate costs nothing.
    if (_isAiExtraction(widget.channel)) {
      if (!await QuotaGates.extractWithAi(context)) return;
    }
    _cancelAutoRun();
    await _voice?.stopListening();
    if (FeaturesFlags.ingestRecent.isEnabled) {
      unawaited(RecentInputsStore.instance.add(value, widget.channel));
    }
    switch (widget.channel) {
      case RecipeIngestionChannel.rawText:
        bloc.add(.parseRawText(value));
      case RecipeIngestionChannel.webSearch:
        bloc.add(.searchWeb(value));
      case RecipeIngestionChannel.urlScrape:
        bloc.add(.parseUrl(value));
      case RecipeIngestionChannel.socialVideo:
        bloc.add(.parseSocialVideo(value));
      case RecipeIngestionChannel.aiRequest:
        bloc.add(.generateRecipe(value));
      case RecipeIngestionChannel.manual:
      case RecipeIngestionChannel.file:
        // Submitted from their own controls.
        break;
    }
  }

  /// Opens the system picker on the formats the model reads, several at a
  /// time. Each file is read at once, so the share-sheet copy and a picked
  /// file take the same path from here on.
  Future<void> _pickFiles() async {
    // A second tap before the rebuild greys the button out.
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final images = _photosAllowed;
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...IngestionFile.pickerExtensions,
          if (images) ...IngestionFile.imageMimeTypes.keys,
        ],
      );
      if (!mounted) return;
      final added = <IngestionFile>[];
      var unsupported = false;
      // Sized from disk before any is read: a long recording read whole
      // only to be refused held hundreds of megabytes for nothing.
      var total = _files.fold<int>(0, (sum, f) => sum + f.bytes.length);
      for (final entry in picked) {
        final path = entry.path;
        if (path == null) continue;
        final name = path.split(Platform.pathSeparator).last;
        final mimeType = IngestionFile.mimeTypeFor(name, images: images);
        if (mimeType == null) {
          unsupported = true;
          continue;
        }
        final file = File(path);
        // A photo is counted after it is made small, below; a phone
        // photo's size on disk says little about what is sent.
        if (mimeType.startsWith('image/')) {
          final shrunk = await RecipeImageShrinker.shrink(
            IngestionFile(
              name: name,
              bytes: await file.readAsBytes(),
              mimeType: mimeType,
            ),
          );
          total += shrunk.bytes.length;
          if (total > IngestionFile.maxBytes) {
            if (mounted) {
              AppDialog.warning(
                message: t.ingestion.fileTooLarge,
              ).notify(context);
            }
            return;
          }
          added.add(shrunk);
          continue;
        }
        total += await file.length();
        if (total > IngestionFile.maxBytes) {
          if (mounted) {
            AppDialog.warning(
              message: t.ingestion.fileTooLarge,
            ).notify(context);
          }
          return;
        }
        final bytes = await file.readAsBytes();
        added.add(IngestionFile(name: name, bytes: bytes, mimeType: mimeType));
      }
      if (!mounted) return;
      if (unsupported) {
        AppDialog.warning(
          message: images
              ? t.ingestion.filePhotoUnsupported
              : t.ingestion.fileUnsupported,
        ).notify(context);
      }
      if (added.isEmpty) return;
      if (IngestionFile.tooLarge([..._files, ...added])) {
        AppDialog.warning(message: t.ingestion.fileTooLarge).notify(context);
        return;
      }
      setState(() => _files.addAll(added));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  static final _imagePicker = ImagePicker();

  /// A photo of a recipe from the camera, or several from the gallery (the
  /// pages of one recipe). The picker scales and re-encodes on the way out;
  /// the shrinker then evens out what it leaves (a PNG screenshot stays a
  /// PNG on Android), so every page goes as a JPEG of a few hundred KB.
  Future<void> _pickPhotos(ImageSource source) async {
    if (!guardFeature(context, FeaturesFlags.ingestPhoto)) return;
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final shot = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: RecipeImageShrinker.maxSide.toDouble(),
          maxHeight: RecipeImageShrinker.maxSide.toDouble(),
          imageQuality: RecipeImageShrinker.quality,
        );
        picked = [?shot];
      } else {
        picked = await _imagePicker.pickMultiImage(
          maxWidth: RecipeImageShrinker.maxSide.toDouble(),
          maxHeight: RecipeImageShrinker.maxSide.toDouble(),
          imageQuality: RecipeImageShrinker.quality,
        );
      }
      if (picked.isEmpty || !mounted) return;
      final added = <IngestionFile>[];
      for (final photo in picked) {
        final mimeType =
            IngestionFile.mimeTypeFor(photo.name, images: true) ?? 'image/jpeg';
        added.add(
          await RecipeImageShrinker.shrink(
            IngestionFile(
              name: photo.name,
              bytes: await photo.readAsBytes(),
              mimeType: mimeType,
            ),
          ),
        );
      }
      if (!mounted) return;
      if (IngestionFile.tooLarge([..._files, ...added])) {
        AppDialog.warning(message: t.ingestion.fileTooLarge).notify(context);
        return;
      }
      setState(() => _files.addAll(added));
    } catch (e) {
      // A refused camera permission or a picker that broke: said, not
      // swallowed.
      debugPrint('Recipe photo failed: $e');
      if (mounted) AppDialog.error(message: t.common.error).notify(context);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// True while a submit is between the tap and the bloc: the quota gate
  /// records an extraction (or opens the ad sheet) before the bloc's own
  /// "already parsing" guard can see a second tap, so a double tap counted
  /// two extractions for one analysis.
  bool _submitting = false;

  Future<void> _once(Future<void> Function() run) async {
    if (_submitting) return;
    _submitting = true;
    try {
      await run();
    } finally {
      _submitting = false;
    }
  }

  Future<void> _submitFiles() async {
    if (_files.isEmpty) return;
    final bloc = context.read<IngestionBloc>();
    if (!await QuotaGates.extractWithAi(context)) return;
    bloc.add(.parseFiles(List.of(_files)));
  }

  /// The chosen files as rows — what each is, how big, a way to drop it —
  /// and a note that together they are read as one recipe.
  Widget _fileCard() {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChannelIntro(channel: RecipeIngestionChannel.file),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _photosAllowed ? t.ingestion.filePhotoHint : t.ingestion.fileHint,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (_files.isNotEmpty) const SizedBox(height: AppSpacing.xs),
          for (final (index, file) in _files.indexed) ...[
            const SizedBox(height: AppSpacing.sm),
            _FileRow(
              file: file,
              // The order is the order the parts are read in.
              ordinal: _files.length > 1 ? index + 1 : null,
              onRemove: () => setState(() => _files.removeAt(index)),
            ),
          ],
          if (_files.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.ingestion.filesAsOne(count: _files.length),
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
          if (_files.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.ingestion.shareMoreHint,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: _files.isEmpty
                ? t.ingestion.chooseFile
                : t.ingestion.addFile,
            icon: _files.isEmpty
                ? Icons.folder_open_rounded
                : Icons.add_rounded,
            onPressed: _picking ? null : _pickFiles,
          ),
          // A cookbook page, a screenshot, a handwritten card — straight
          // from the camera or the gallery, without going through Files.
          FeatureGate(
            feature: FeaturesFlags.ingestPhoto,
            gapBefore: AppSpacing.sm,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ClayButton(
                  label: t.ingestion.takePhoto,
                  icon: Icons.photo_camera_rounded,
                  onPressed: _picking
                      ? null
                      : () => _pickPhotos(ImageSource.camera),
                ),
                ClayButton(
                  label: t.ingestion.fromGallery,
                  icon: Icons.photo_library_rounded,
                  onPressed: _picking
                      ? null
                      : () => _pickPhotos(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The microphone at the end of the box; a stop square while it listens.
  Widget _voiceButton() {
    final voice = _voice;
    Widget button(bool listening) => IconButton(
      tooltip: listening ? t.ingestion.voiceStop : t.ingestion.voiceStart,
      icon: Icon(
        listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
        color: listening ? AppColors.error : AppColors.primary,
      ),
      onPressed: _toggleVoice,
    );
    if (voice == null) return button(false);
    return ValueListenableBuilder<bool>(
      valueListenable: voice.listening,
      builder: (context, listening, _) => button(listening),
    );
  }

  /// What the analyse button says on an AI channel: the plain label while
  /// nothing is counted, "watch a video and parse" while a free account has
  /// extractions left, and a disabled "locked for today" once the day's
  /// allowance — free or premium — is spent.
  Widget _parseButton() {
    final isFile = widget.channel == RecipeIngestionChannel.file;
    final ready = isFile ? _files.isNotEmpty : _hasInput;
    final run = isFile ? _submitFiles : _submit;
    Future<void> submit() => _once(run);
    if (!_isAiExtraction(widget.channel) || !MonetizationConfig.aiGated) {
      return ClayButton(
        // A request is not analysed, it is written — the button says so.
        label: widget.channel == RecipeIngestionChannel.aiRequest
            ? t.ingestion.generate
            : t.ingestion.parse,
        icon: Icons.auto_awesome_rounded,
        expanded: true,
        onPressed: ready ? submit : null,
      );
    }
    final verdict = DailyQuotaPolicy.aiExtraction(
      usedToday: DailyUsageService().aiExtractionsToday,
      premium: MonetizationConfig.isPremium,
      limits: MonetizationConfig.limits,
    );
    return switch (verdict) {
      GateVerdict.blocked => ClayButton(
        label: t.ads.blockedForToday,
        icon: Icons.lock_outline_rounded,
        expanded: true,
      ),
      GateVerdict.rewarded => ClayButton(
        label: t.ads.parseWithVideo,
        icon: Icons.play_circle_rounded,
        expanded: true,
        onPressed: ready ? submit : null,
      ),
      GateVerdict.free => ClayButton(
        label: t.ingestion.parse,
        icon: Icons.auto_awesome_rounded,
        expanded: true,
        onPressed: ready ? submit : null,
      ),
    };
  }

  /// A recipe written by hand starts from the same structured editor a parsed
  /// one is corrected in — the format is the format, whoever fills it.
  Future<void> _openBlankEditor() async {
    final bloc = context.read<IngestionBloc>();
    final result = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: buildBlankRecipe(id: const Uuid().v4()),
    );
    if (result != null) bloc.add(.saveRecipe(result));
  }

  @override
  Widget build(BuildContext context) {
    // The channel on screen was switched off in the console (or was never
    // allowed): the first one that is allowed takes its place.
    if (!_channelAllowed(widget.channel)) {
      final fallback = RecipeIngestionChannel.values
          .where(_channelAllowed)
          .firstOrNull;
      if (fallback != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<IngestionBloc>().add(.selectChannel(fallback));
          }
        });
      }
    }
    final channel = widget.channel;
    final textChannel = _hasTextField(channel);
    Widget chip(RecipeIngestionChannel c) => _ChannelChip(
      channel: c,
      selected: channel == c,
      onTap: () => _pickChannel(c),
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        ClayPageHeader(title: t.ingestion.title),
        const SizedBox(height: AppSpacing.md),
        // What to give first — the text, the files, or the empty editor —
        // then the day's allowance, then the category it is read as.
        if (channel == RecipeIngestionChannel.manual)
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _ChannelIntro(channel: channel),
          )
        else if (channel == RecipeIngestionChannel.file)
          _fileCard()
        else
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalkthroughTarget(
                  id: WalkthroughIds.ingestionInput,
                  child: TextField(
                    controller: _controller,
                    // In auto mode the box keeps one size while the category
                    // moves under it; a chosen category sizes it to its input.
                    minLines: _auto ? 3 : null,
                    maxLines: _auto
                        ? 8
                        : switch (channel) {
                            RecipeIngestionChannel.rawText => 8,
                            RecipeIngestionChannel.aiRequest => 4,
                            _ => 2,
                          },
                    inputFormatters: [
                      // While the app picks, a pasted recipe must not be cut to
                      // the search box's length before it is recognised; the
                      // submit checks the chosen channel's own limit.
                      LengthLimitingTextInputFormatter(
                        _auto
                            ? maxCharsFor(RecipeIngestionChannel.rawText)
                            : maxCharsFor(channel),
                      ),
                    ],
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      hintText: _hint,
                      suffixIcon: FeaturesFlags.ingestVoice.isVisible
                          ? _voiceButton()
                          : null,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.quick,
                  curve: AppMotion.easeOut,
                  alignment: AlignmentDirectional.topStart,
                  child: _autoRunLeft > 0
                      ? _AutoRunBar(
                          seconds: _autoRunLeft,
                          onCancel: _cancelAutoRun,
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (_recent.isNotEmpty &&
                    !_hasInput &&
                    FeaturesFlags.ingestRecent.isEnabled)
                  _RecentInputs(
                    recent: _recent,
                    onTap: _useRecent,
                    onRemove: _removeRecent,
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_showsAiQuota(channel)) const AiQuotaIndicator(),
        // The question the chips answer, so the row reads as a choice and
        // not as a set of tags.
        Text(
          t.ingestion.chooseSource,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        WalkthroughTarget(
          id: WalkthroughIds.ingestionChannels,
          child: Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.base,
            children: [
              for (final c in RecipeIngestionChannel.values)
                if (channelFeature(c) case final feature?)
                  FeatureGate(feature: feature, compact: true, child: chip(c))
                else
                  chip(c),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _CategoryNote(
          auto: _auto,
          empty: !_hasInput,
          explaining: _explained == channel && textChannel,
        ),
        AnimatedSize(
          duration: AppMotion.quick,
          curve: AppMotion.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: _explained == channel && textChannel
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _ChannelExplanation(channel: channel),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (channel == RecipeIngestionChannel.manual)
          ClayButton(
            label: t.ingestion.openBlankEditor,
            icon: Icons.edit_note_rounded,
            expanded: true,
            onPressed: _openBlankEditor,
          )
        else ...[
          ListenableBuilder(
            listenable: Listenable.merge([
              DailyUsageService(),
              EntitlementService(),
              FirebaseService().configRevision,
            ]),
            builder: (context, _) => _parseButton(),
          ),
          if (widget.channel == RecipeIngestionChannel.webSearch)
            FeatureGate(
              feature: FeaturesFlags.recipeSuggestions,
              gapBefore: AppSpacing.md,
              child: _OpenOption(
                icon: Icons.tips_and_updates_rounded,
                title: t.ingestion.suggestForMe,
                hint: t.ingestion.suggestForMeHint,
                onTap: () => _once(() async {
                  if (!guardFeature(context, FeaturesFlags.recipeSuggestions)) {
                    return;
                  }
                  final bloc = context.read<IngestionBloc>();
                  // The sheet starts from the diet in the settings; what is
                  // changed there is for this search only.
                  final saved = await bloc.savedPreferences();
                  final savedAllergens = await bloc.savedAllergens();
                  if (!context.mounted) return;
                  final request = await showSuggestionRequestSheet(
                    context,
                    saved: saved,
                    savedAllergens: savedAllergens,
                  );
                  if (request == null) return;
                  bloc.add(
                    IngestionEvent.suggestRecipes(
                      topic: request.topic,
                      preferences: request.diet,
                      allergens: request.allergens,
                    ),
                  );
                }),
              ),
            ),
        ],
        // Several recipes at once: a pasted list or a WhatsApp export.
        const BulkImportEntry(),
      ],
    );
  }
}

/// The line under the category chips: that the app picked the category
/// (or will, once something is typed), or else how to learn what each one
/// does. Hidden while an explanation is open.
class _CategoryNote extends StatelessWidget {
  final bool auto;
  final bool empty;
  final bool explaining;

  const _CategoryNote({
    required this.auto,
    required this.empty,
    required this.explaining,
  });

  @override
  Widget build(BuildContext context) {
    if (explaining && !auto) return const SizedBox.shrink();
    final color = auto ? AppColors.primary : AppColors.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          auto ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            !auto
                ? t.ingestion.tapForInfo
                : empty
                ? t.ingestion.autoWaiting
                : t.ingestion.autoPicked,
            style: AppTextStyles.labelMd.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// What the tapped category does, opened under the chip row.
class _ChannelExplanation extends StatelessWidget {
  final RecipeIngestionChannel channel;

  const _ChannelExplanation({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _ChannelIntro(channel: channel),
    );
  }
}

/// "Starting in 2…" under a pasted link, with a way to stop it.
class _AutoRunBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;

  const _AutoRunBar({required this.seconds, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              t.ingestion.autoRunIn(seconds: seconds),
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(onPressed: onCancel, child: Text(t.common.cancel)),
        ],
      ),
    );
  }
}

/// The last few searches, links and requests, under an empty box: a tap
/// puts one back, the x forgets it.
class _RecentInputs extends StatelessWidget {
  final List<RecentInput> recent;
  final ValueChanged<RecentInput> onTap;
  final ValueChanged<RecentInput> onRemove;

  const _RecentInputs({
    required this.recent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.ingestion.recentTitle,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final input in recent)
                InputChip(
                  avatar: Icon(
                    _channelIcon(input.channel),
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      input.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMd,
                    ),
                  ),
                  onPressed: () => onTap(input),
                  onDeleted: () => onRemove(input),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One way in, as a pill: icon and name, filled when it is the one chosen.
class _ChannelChip extends StatelessWidget {
  final RecipeIngestionChannel channel;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.onPrimary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.base + 2,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          shadows: selected ? AppShadows.control : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_channelIcon(channel), size: 18, color: ink),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              _channelLabel(channel),
              style: AppTextStyles.labelMd.copyWith(
                color: ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The head of a channel's card: its icon in a medallion, its name, and the
/// full explanation of what it does — the same block on every channel.
class _ChannelIntro extends StatelessWidget {
  final RecipeIngestionChannel channel;

  const _ChannelIntro({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _channelIcon(channel),
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _channelLabel(channel),
                style: AppTextStyles.headlineMd,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _channelDescription(channel),
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// One file on the list: its kind, name, size, and an x to drop it.
class _FileRow extends StatelessWidget {
  final IngestionFile file;
  final int? ordinal;
  final VoidCallback onRemove;

  const _FileRow({
    required this.file,
    required this.ordinal,
    required this.onRemove,
  });

  static String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) {
      return t.ingestion.sizeKb(n: '${(bytes / 1024).round()}');
    }
    return t.ingestion.sizeMb(n: (bytes / (1024 * 1024)).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: ordinal != null
              ? Text(
                  '$ordinal',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  file.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : file.isImage
                      ? Icons.image_rounded
                      : Icons.graphic_eq_rounded,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd,
              ),
              Text(
                '${file.isPdf
                    ? 'PDF'
                    : file.isImage
                    ? t.ingestion.photoTag
                    : t.ingestion.recordingTag} · '
                '${_sizeLabel(file.bytes.length)}',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ClayIconButton(
          icon: Icons.close_rounded,
          size: 32,
          tooltip: t.common.delete,
          onTap: onRemove,
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<WebSearchResultEntity> results;

  /// The list came from the account's preferences: it says so on top, ticks
  /// what was saved from it, and ends with a way out.
  final bool suggested;
  final List<String> savedUrls;

  const _SearchResults({
    required this.results,
    this.suggested = false,
    this.savedUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return ClayEmptyState(
        icon: Icons.search_off_rounded,
        message: suggested
            ? t.ingestion.suggestionsEmpty
            : t.ingestion.parseError,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        if (suggested) ...[
          ClayPageHeader(title: t.ingestion.suggestionsTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.ingestion.suggestionsHint,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final (index, result) in results.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _ResultCard(result: result, saved: savedUrls.contains(result.url)),
        ],
        if (suggested) ...[
          const SizedBox(height: AppSpacing.lg),
          ClayButton(
            label: t.ingestion.suggestionsDone,
            icon: Icons.check_rounded,
            expanded: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final WebSearchResultEntity result;
  final bool saved;

  const _ResultCard({required this.result, this.saved = false});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: () => showOpenRecipeSheet(context, result.url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(result.title, style: AppTextStyles.bodyLg)),
              if (saved) ...[
                const SizedBox(width: AppSpacing.sm),
                ClayTag(
                  label: t.ingestion.savedTag,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRecipe extends StatelessWidget {
  final RecipeEntity recipe;

  /// The pictures offered for a video recipe, and which one is on it.
  final List<RecipeImageCandidate> imageCandidates;
  final int? selectedImage;

  const _ReviewRecipe({
    required this.recipe,
    this.imageCandidates = const [],
    this.selectedImage,
  });

  /// The editor is reached by route name so ingestion never reaches into
  /// another feature's presentation layer, and it pops the edited recipe back.
  Future<void> _openEditor(BuildContext context, RecipeEntity current) async {
    final bloc = context.read<IngestionBloc>();
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: current,
    );
    if (edited != null) bloc.add(IngestionEvent.updateRecipe(edited));
  }

  @override
  Widget build(BuildContext context) {
    final actions = Row(
      children: [
        ClayButton(
          label: t.common.edit,
          icon: Icons.edit_rounded,
          onPressed: () => _openEditor(context, recipe),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClayButton(
            label: t.common.save,
            icon: Icons.bookmark_added_rounded,
            expanded: true,
            onPressed: () =>
                context.read<IngestionBloc>().add(.saveRecipe(recipe)),
          ),
        ),
      ],
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              // Sideways here too, as in the editor it opens: the review
              // is the first screen a new recipe is checked on.
              const LandscapeHint(),
              const SizedBox(height: AppSpacing.md),
              ClayTag(
                label: t.ingestion.reviewTitle,
                icon: Icons.fact_check_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(recipe.title, style: AppTextStyles.headlineLgMobile),
              // A video recipe arrives with pictures to choose from: the
              // post's cover is already on it, the stills are the
              // alternatives. The gate draws coming-soon / Premium itself.
              if (imageCandidates.isNotEmpty)
                FeatureGate(
                  feature: FeaturesFlags.socialVideoPhoto,
                  gapBefore: AppSpacing.md,
                  child: VideoImagePicker(
                    candidates: imageCandidates,
                    selected: selectedImage,
                    onPick: (index) => context.read<IngestionBloc>().add(
                      IngestionEvent.pickImageCandidate(index),
                    ),
                  ),
                ),
              RecipeSourceLink(url: recipe.sourceUrl, gapBefore: AppSpacing.md),
              // The tags the analysis settled on, up front so a wrong one is
              // seen — and changed in the editor — before the recipe is saved.
              if (recipe.dietaryTags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.base,
                  runSpacing: AppSpacing.base,
                  children: recipe.dietaryTags.map((tag) {
                    final (background, foreground) = dietaryColors(tag);
                    return ClayTag(
                      label: dietaryLabel(tag),
                      icon: dietaryIcon(tag),
                      background: background,
                      foreground: foreground,
                    );
                  }).toList(),
                ),
              ],
              AllergenNotice(
                allergens: recipe.allergens,
                mayContain: recipe.mayContain,
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClaySectionHeader(
                      title: t.recipe.ingredients,
                      underline: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final (index, ingredient)
                        in recipe.ingredients.indexed) ...[
                      ?IngredientSectionHeading.at(recipe.ingredients, index),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _ingredientLine(ingredient),
                                style: AppTextStyles.bodyMd,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClaySectionHeader(
                      title: t.recipe.instructions,
                      underline: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...recipe.steps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.base,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTextStyles.bodyMd,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (FeaturesFlags.reviewStickySave.isEnabled)
          _PinnedActionBar(child: actions)
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: actions,
          ),
      ],
    );
  }
}

/// The review's edit and save, as a bar that sits on the screen's bottom
/// edge: raised above the list with a hairline and a shadow, so on a long
/// recipe it reads as always there rather than as the list's last row. It
/// sits under the list, never over it, so nothing scrolls behind it; the
/// bottom inset (a home indicator in landscape) is kept clear.
class _PinnedActionBar extends StatelessWidget {
  final Widget child;

  const _PinnedActionBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: BorderDirectional(
          top: BorderSide(color: AppColors.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavenderGlow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final RecipeIngestionChannel channel;
  final String error;

  const _ErrorView({required this.channel, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(t.ingestion.parseError, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.base),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: t.common.retry,
                icon: Icons.refresh_rounded,
                // The same request again (or the search results back), not
                // an empty form.
                onPressed: () =>
                    context.read<IngestionBloc>().add(const .retry()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The choice between reading the page as-is and having the model structure
/// it. Searching used to commit to the model on tap; asking here is what keeps
/// the search itself cheap.
Future<void> showOpenRecipeSheet(BuildContext context, String url) async {
  final bloc = context.read<IngestionBloc>();
  final generate = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(
              title: t.ingestion.openOptionsTitle,
              underline: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _OpenOption(
              icon: Icons.article_rounded,
              title: t.ingestion.viewOriginal,
              hint: t.ingestion.viewOriginalHint,
              onTap: () => popIfCurrent(sheetContext, false),
            ),
            const SizedBox(height: AppSpacing.sm),
            _OpenOption(
              icon: Icons.auto_awesome_rounded,
              title: t.ingestion.generateStructured,
              hint: t.ingestion.generateStructuredHint,
              onTap: () => popIfCurrent(sheetContext, true),
            ),
          ],
        ),
      ),
    ),
  );
  if (generate == null || !context.mounted) return;
  if (!generate) {
    bloc.add(IngestionEvent.viewOriginal(url));
    return;
  }
  await _extractUrl(context, url);
}

class _OpenOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _OpenOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLg),
                Text(
                  hint,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

/// The page text as fetched. The structured path stays one tap away, so
/// someone who read the original and wants it saved does not have to search
/// again.
class _OriginalView extends StatelessWidget {
  final OriginalRecipePageEntity page;

  const _OriginalView({required this.page});

  @override
  Widget build(BuildContext context) {
    final structured = page.structured;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayTag(
                label: t.ingestion.originalTitle,
                icon: Icons.article_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (page.title case final title?) ...[
                Text(title, style: AppTextStyles.headlineLgMobile),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                page.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(page.text, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          // The site published its recipe as data: the structured path is one
          // tap and free, so it leads; the model stays available for anyone
          // who wants its take on the amounts.
          child: structured != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.ingestion.structuredFromSite,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClayButton(
                      label: t.ingestion.useStructured,
                      icon: Icons.check_rounded,
                      expanded: true,
                      onPressed: () => context.read<IngestionBloc>().add(
                        .updateRecipe(structured),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _extractUrl(context, page.url),
                      child: Text(
                        t.ingestion.preferAi,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                )
              : ClayButton(
                  label: t.ingestion.generateStructured,
                  icon: Icons.auto_awesome_rounded,
                  expanded: true,
                  onPressed: () => _extractUrl(context, page.url),
                ),
        ),
      ],
    );
  }
}

/// Shown when the analysis timed out or failed. The text is safe either way;
/// what is offered is what to do with it, never a dead end.
class _UnparsedView extends StatelessWidget {
  final RecipeIngestionChannel channel;
  final String text;
  final String? sourceUrl;
  final bool timedOut;

  /// False after a refusal that stands (quota, phone, blocked account):
  /// the Retry button is greyed, the other two ways out stay.
  final bool retryable;

  const _UnparsedView({
    required this.channel,
    required this.text,
    required this.sourceUrl,
    required this.timedOut,
    this.retryable = true,
  });

  /// Retries the same analysis, not a different one: a link is re-parsed as a
  /// link, pasted text as text. Deliberately not behind the quota gate: the
  /// extraction was paid for when it started, and a slow model is not the
  /// user's fault.
  void _retry(BuildContext context) {
    final bloc = context.read<IngestionBloc>();
    final url = sourceUrl;
    switch (channel) {
      case RecipeIngestionChannel.socialVideo when url != null:
        bloc.add(.parseSocialVideo(url));
      case RecipeIngestionChannel.urlScrape || RecipeIngestionChannel.webSearch
          when url != null:
        bloc.add(.parseUrl(url));
      case RecipeIngestionChannel.aiRequest:
        bloc.add(.generateRecipe(text));
      case _:
        bloc.add(.parseRawText(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<IngestionBloc>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayTag(
                label: timedOut
                    ? t.ingestion.analysisTimedOut
                    : t.ingestion.analysisFailed,
                icon: timedOut
                    ? Icons.hourglass_bottom_rounded
                    : Icons.error_outline_rounded,
                background: AppColors.errorContainer,
                foreground: AppColors.onErrorContainer,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.ingestion.unparsedHint,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(text, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayButton(
                label: t.ingestion.saveForLater,
                icon: Icons.bookmark_add_rounded,
                expanded: true,
                onPressed: () =>
                    bloc.add(.saveAsTemplate(text, sourceUrl: sourceUrl)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      label: t.ingestion.editManually,
                      icon: Icons.edit_rounded,
                      expanded: true,
                      onPressed: () =>
                          bloc.add(.editManually(text, sourceUrl: sourceUrl)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClayButton(
                      label: t.ingestion.retryAnalysis,
                      icon: Icons.refresh_rounded,
                      expanded: true,
                      onPressed: retryable ? () => _retry(context) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _ingredientLine(RecipeIngredientEntity ingredient) => [
  ingredient.isAmountMissing
      ? kMissingInfoPlaceholder
      : ingredient.displayAmount,
  measurementUnitLabel(ingredient.unit),
  ingredient.name,
].where((s) => s.isNotEmpty).join(' ');
