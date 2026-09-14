import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_flip/page_flip.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'book_spread_flip.dart';
import 'quick_jump_capsule.dart';

/// Moves the reader through an open book. Handed to the page and action
/// builders so a contents row or a capsule button can turn to a page.
abstract class BookNavigator {
  int get currentPage;

  /// Turns to [page], riffling through every page in between when the fast
  /// page-turn preference is on, or cutting straight there when it is off.
  Future<void> goTo(int page);
}

/// A book lying open on the lavender desk: the page stock inside a rounded
/// clip, the frosted capsule floating above it, and the page turn itself.
///
/// Every book in the app — a real one from the library, a sample in the
/// guide, the guide itself — is this one widget with different pages, so
/// they cannot drift apart in look or feel.
///
/// The only place the app may be turned on its side, and only on a tablet:
/// a phone's half-width page is too narrow to read. Upright it shows one
/// page at a time; on its side, two pages on a spine, turned like a real
/// book. The page being read carries across the turn.
class OpenBookShell extends StatefulWidget {
  /// Covers everything that can change on a page. `PageFlipWidget` snapshots
  /// its children in initState and ignores later updates, so a change that
  /// should redraw the book has to change this key.
  final Key? bookKey;

  final List<Widget> Function(BookNavigator book) pages;
  final List<QuickJumpAction> Function(BookNavigator book) actions;

  const OpenBookShell({
    super.key,
    required this.pages,
    required this.actions,
    this.bookKey,
  });

  /// How long a single page takes to turn. Every jump is played out as a
  /// sequence of real page turns at this cadence, so it reads as riffling
  /// through the book rather than teleporting.
  static const pageFlipDuration = Duration(milliseconds: 300);

  /// Vertical room the floating capsule occupies, so the book can be inset by
  /// this plus a gap and the two never touch.
  static const capsuleHeight = 72.0;

  @override
  State<OpenBookShell> createState() => _OpenBookShellState();
}

class _OpenBookShellState extends State<OpenBookShell> implements BookNavigator {
  /// Books open at once — a sample book opens over the guide — so the
  /// portrait lock only comes back when the last of them closes.
  static int _openBooks = 0;

  /// The shortest side a screen needs to count as a tablet, in logical
  /// pixels — the same line Material draws between compact and medium.
  static const tabletShortestSide = 600.0;

  /// Whether this book let the screen turn, and so has to lock it again.
  bool _unlocked = false;

  final _controller = PageFlipController();
  final _spread = BookSpreadController();
  int _currentPage = 0;
  int _pageCount = 0;
  bool _soundEnabled = true;
  bool _fastPageTurnEnabled = true;

  /// Incremented on every jump so an in-flight fast-forward abandons itself
  /// when the reader picks a new destination mid-animation.
  int _navigationGeneration = 0;

  /// Resolved by [_onPageFlipped] when the page currently turning has landed.
  Completer<void>? _flipCompleter;

  @override
  int get currentPage => _currentPage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// The screen size is only known once the tree is up, so the unlock waits
  /// for it — and happens once, whatever the size does afterwards.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_unlocked) return;
    if (MediaQuery.sizeOf(context).shortestSide < tabletShortestSide) return;
    _unlocked = true;
    if (_openBooks++ == 0) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  void dispose() {
    if (_unlocked && --_openBooks == 0) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  /// The sound and fast-turn preferences, when the tree provides them. A
  /// book shown somewhere without the repositories — a test, a preview —
  /// keeps the defaults rather than failing to open.
  void _loadPreferences() {
    try {
      GetUserPreferencesUseCase(context.read()).call().then((prefs) {
        if (!mounted) return;
        setState(() {
          _soundEnabled = prefs.soundEffectsEnabled;
          _fastPageTurnEnabled = prefs.fastPageTurnEnabled;
        });
      });
    } catch (_) {
      // No preferences repository above this widget; the defaults stand.
    }
  }

  /// Turns a single page and resolves once its flip animation has landed.
  ///
  /// `PageFlipController` returns void rather than the state's future, so the
  /// `onPageFlipped` callback is what tells us the turn finished — that keeps
  /// the run paced by the real animation instead of a guessed delay. The
  /// timeout is a safety net: at either end of the book the flip is refused
  /// and the callback never fires.
  Future<void> _turnOnePage({required bool forward}) {
    final completer = Completer<void>();
    _flipCompleter = completer;
    forward ? _controller.nextPage() : _controller.previousPage();
    return completer.future.timeout(
      OpenBookShell.pageFlipDuration * 3,
      // Detach the abandoned completer so a late landing can't resolve the
      // *next* turn early and cascade the run out of step.
      onTimeout: () {
        if (identical(_flipCompleter, completer)) _flipCompleter = null;
      },
    );
  }

  @override
  Future<void> goTo(int page) async {
    if (_pageCount == 0) return;
    final target = page.clamp(0, _pageCount - 1);
    if (_landscape) return _goToSpread(target ~/ 2);
    final distance = target - _currentPage;
    if (distance == 0) return;

    final generation = ++_navigationGeneration;

    if (!_fastPageTurnEnabled) {
      // goToPage skips the animation and, unlike a real turn, never reports
      // back through onPageFlipped — so the current page is tracked here.
      _controller.goToPage(target);
      setState(() => _currentPage = target);
      return;
    }

    final forward = distance > 0;
    for (var i = 0; i < distance.abs(); i++) {
      // A newer jump (or a disposed book) retires this run mid-flight.
      if (!mounted || generation != _navigationGeneration) return;
      await _turnOnePage(forward: forward);
    }
  }

  /// The spread's leaves turn one at a time like the single pages do, at
  /// the spread widget's own cadence; its controller resolves per landing,
  /// so no completer is needed here.
  Future<void> _goToSpread(int target) async {
    final distance = target - _spread.spread;
    if (distance == 0) return;
    final generation = ++_navigationGeneration;

    if (!_fastPageTurnEnabled) {
      _spread.jumpTo(target);
      return;
    }
    final forward = distance > 0;
    for (var i = 0; i < distance.abs(); i++) {
      if (!mounted || generation != _navigationGeneration) return;
      await (forward ? _spread.next() : _spread.previous());
    }
  }

  void _onSpreadChanged(int spread) {
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
    // Only move when the page being read is not on this spread already, so
    // turning the phone back does not lose an odd page for its even twin.
    if (_currentPage ~/ 2 != spread) setState(() => _currentPage = 2 * spread);
  }

  bool _landscape = false;

  void _onPageFlipped(int page) {
    setState(() => _currentPage = page);
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
    // Releases the fast-forward loop to start the next turn.
    if (_flipCompleter?.isCompleted == false) _flipCompleter!.complete();
    _flipCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages(this);
    _pageCount = pages.length;
    _landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: DecoratedBox(
        // Soft lavender environment so the book reads as an object resting
        // on a surface, per the Stitch index screen.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceContainer, AppColors.surfaceDim],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  OpenBookShell.capsuleHeight + AppSpacing.base,
                  AppSpacing.gutter,
                  AppSpacing.gutter,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.std),
                  child: _landscape
                      ? BookSpreadFlip(
                          key: widget.bookKey,
                          pages: pages,
                          initialSpread: _currentPage ~/ 2,
                          controller: _spread,
                          onSpreadChanged: _onSpreadChanged,
                          duration: OpenBookShell.pageFlipDuration * 2,
                          backgroundColor: AppColors.surfaceBright,
                        )
                      : PageFlipWidget(
                          key: widget.bookKey,
                          controller: _controller,
                          duration: OpenBookShell.pageFlipDuration,
                          backgroundColor: AppColors.surfaceBright,
                          isRightSwipe: true,
                          initialIndex: _currentPage.clamp(0, pages.length - 1),
                          onPageFlipped: _onPageFlipped,
                          children: pages,
                        ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: QuickJumpCapsule(actions: widget.actions(this)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
