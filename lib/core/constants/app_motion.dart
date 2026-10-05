import 'package:flutter/widgets.dart';

/// Motion tokens: every duration and curve the interface animates with.
///
/// The house style follows Apple's fluid-interface rules. Motion is
/// critically damped by default — it settles without overshoot — and a
/// bounce is reserved for the one case the gesture itself carried momentum
/// (a flick, a drag released), where the overshoot *is* the momentum.
/// Everything a finger triggers responds on touch-down, within [press].
abstract class AppMotion {
  /// Press feedback: a surface sinking or shrinking under the finger.
  static const press = Duration(milliseconds: 110);

  /// Small state changes: a chip filling in, a label changing weight, an
  /// icon turning, a selection ring.
  static const quick = Duration(milliseconds: 180);

  /// A pill sliding to a new segment, a row expanding, a bar filling.
  static const standard = Duration(milliseconds: 240);

  /// A card or a notice arriving: large enough to read as an entrance.
  static const emphasized = Duration(milliseconds: 300);

  /// Leaving is quicker than arriving — the system responds, the user is
  /// not asked to watch it go.
  static const exit = Duration(milliseconds: 180);

  /// Strong ease-out: fast off the mark, long settle. Entrances, state
  /// changes, anything the user is watching the first frames of.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out for something already on screen moving somewhere
  /// else — a theme reveal, a reorder.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// The iOS drawer curve, for sheets and anything that slides in from an
  /// edge.
  static const drawer = Cubic(0.32, 0.72, 0, 1);

  /// A gentle overshoot (about the response of a spring at damping 0.8):
  /// only for the landing after a drag or a flick, where the finger's
  /// momentum has to go somewhere.
  static const settle = Cubic(0.34, 1.28, 0.64, 1);

  /// Whether the device asks for reduced motion (iOS Reduce Motion, the
  /// Android animator scale switched off).
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration] for a movement — a slide, a scale, a rotation. Reduced
  /// motion cuts it to nothing: the state still changes, it just stops
  /// travelling.
  static Duration move(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// [duration] for a fade or a colour change. These aid comprehension and
  /// stay under reduced motion, only shorter.
  static Duration fade(BuildContext context, Duration duration) =>
      reduced(context) && duration > quick ? quick : duration;

  /// Where a flick would come to rest on its own, from Apple's
  /// *Designing Fluid Interfaces*: the distance a velocity (px/s) travels
  /// under exponential deceleration. 0.998 is the scroll feel; 0.99 is
  /// snappier, for short controls.
  static double project(double velocity, {double decelerationRate = 0.99}) =>
      (velocity / 1000) * decelerationRate / (1 - decelerationRate);
}
