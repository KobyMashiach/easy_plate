/// Decides, from a camera frame's brightness, whether a receipt is sitting
/// inside the guide frame and holding still — the moment to take the shot.
///
/// A receipt is white paper; the table, the hand and the floor around it
/// are darker. So: the inside of the frame must be mostly bright and
/// clearly brighter than the margins outside it, and the picture must not
/// be changing (no motion blur, no hand still positioning). Only when all
/// three hold for [requiredFrames] frames in a row is the capture fired.
///
/// Pure over a luminance sampler, so it is tested with synthetic frames.
class PaperDetector {
  /// Fractions of the frame's long axis that the guide covers.
  final double guideStart;
  final double guideEnd;

  /// Fractions of the short axis the guide covers.
  final double guideSideStart;
  final double guideSideEnd;

  /// A pixel this bright is paper.
  final int paperLuma;

  /// Share of paper pixels inside the guide needed to call it a receipt.
  final double minPaperShare;

  /// How much brighter the inside must be than the margins.
  final double minContrast;

  /// Mean absolute change between two frames above which the scene moved.
  final double maxMotion;
  final int requiredFrames;

  int _stableFrames = 0;
  double? _lastInsideMean;

  PaperDetector({
    this.guideStart = 0.14,
    this.guideEnd = 0.86,
    this.guideSideStart = 0.08,
    this.guideSideEnd = 0.92,
    this.paperLuma = 150,
    this.minPaperShare = 0.55,
    this.minContrast = 28,
    this.maxMotion = 6,
    this.requiredFrames = 8,
  });

  int get stableFrames => _stableFrames;

  /// The verdict for one frame. [luma] returns 0–255 for a pixel; the frame
  /// is sampled on a coarse grid, which is plenty for "is this paper".
  PaperVerdict feed({
    required int width,
    required int height,
    required int Function(int x, int y) luma,
  }) {
    // The long axis is whichever is longer: the guide runs along it.
    final longIsX = width >= height;
    final long = longIsX ? width : height;
    final short = longIsX ? height : width;
    const grid = 32;
    var insideSum = 0.0;
    var insidePaper = 0;
    var insideCount = 0;
    var outsideSum = 0.0;
    var outsideCount = 0;
    for (var i = 0; i < grid; i++) {
      for (var j = 0; j < grid; j++) {
        final l = ((i + 0.5) / grid);
        final s = ((j + 0.5) / grid);
        final x = ((longIsX ? l : s) * (width - 1)).round();
        final y = ((longIsX ? s : l) * (height - 1)).round();
        final v = luma(x, y);
        final inLong = l >= guideStart && l <= guideEnd;
        final inShort = s >= guideSideStart && s <= guideSideEnd;
        if (inLong && inShort) {
          insideSum += v;
          insideCount++;
          if (v >= paperLuma) insidePaper++;
        } else if (!inLong) {
          // The margins beyond the guide's ends, where the receipt must not be.
          outsideSum += v;
          outsideCount++;
        }
      }
    }
    if (insideCount == 0 || outsideCount == 0 || long == 0 || short == 0) {
      return _reset(PaperState.searching);
    }
    final insideMean = insideSum / insideCount;
    final outsideMean = outsideSum / outsideCount;
    final paperShare = insidePaper / insideCount;
    final motion = _lastInsideMean == null
        ? 0.0
        : (insideMean - _lastInsideMean!).abs();
    _lastInsideMean = insideMean;

    final paper =
        paperShare >= minPaperShare && insideMean - outsideMean >= minContrast;
    if (!paper) return _reset(PaperState.searching);
    if (motion > maxMotion) return _reset(PaperState.moving);
    _stableFrames++;
    return PaperVerdict(
      _stableFrames >= requiredFrames ? PaperState.ready : PaperState.holding,
      progress: (_stableFrames / requiredFrames).clamp(0, 1),
    );
  }

  PaperVerdict _reset(PaperState state) {
    _stableFrames = 0;
    return PaperVerdict(state, progress: 0);
  }

  void reset() {
    _stableFrames = 0;
    _lastInsideMean = null;
  }
}

enum PaperState { searching, moving, holding, ready }

class PaperVerdict {
  final PaperState state;
  final double progress;
  const PaperVerdict(this.state, {required this.progress});
}
