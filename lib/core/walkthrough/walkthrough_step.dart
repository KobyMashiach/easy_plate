/// One thing the walkthrough points at and explains.
class WalkthroughStep {
  final String title;
  final String body;

  /// The [WalkthroughTarget] id to cut out of the dimmed screen. Null for a
  /// step that is only a message, shown in the middle of the screen.
  final String? targetId;

  /// The main tab that has to be showing for the target to exist.
  final int? tab;

  /// The route (a name nested under home) that has to be on top for the
  /// target to exist. Null means the main shell itself — anything pushed over
  /// it is popped first.
  final String? route;

  /// Whether a tap on the target itself is what completes the step. Off for a
  /// target that is only being pointed at, where "next" is the way on.
  final bool advanceOnTap;

  /// The step lives wherever the previous one left the app: inside the
  /// dialog or sheet that step opened, or on a page it pushed with data the
  /// tour cannot supply itself. The tour then neither switches tab nor
  /// pops or pushes anything, and when the target never turns up — the step
  /// before it was skipped, or its dialog closed — the step is passed over
  /// on its own rather than left pointing at nothing.
  final bool stay;

  const WalkthroughStep({
    required this.title,
    required this.body,
    this.targetId,
    this.tab,
    this.route,
    this.advanceOnTap = true,
    this.stay = false,
  });
}

/// A chapter of the guide: one capability, told as a short sequence of steps.
class WalkthroughTopic {
  final String id;
  final String title;
  final String summary;
  final List<WalkthroughStep> steps;

  const WalkthroughTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
  });
}
