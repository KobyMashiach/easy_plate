import 'package:easy_plate/features/price_book/presentation/paper_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 640x480 frame: [paper] luma inside the guide band along x, [table]
/// outside it, with optional noise so two frames differ.
int Function(int, int) frame({required int paper, required int table, int shift = 0}) =>
    (x, y) {
      final l = x / 639;
      final inside = l >= 0.14 && l <= 0.86;
      return ((inside ? paper : table) + shift).clamp(0, 255);
    };

void main() {
  test('an empty table never fires', () {
    final d = PaperDetector();
    for (var i = 0; i < 20; i++) {
      final v = d.feed(width: 640, height: 480, luma: frame(paper: 70, table: 70));
      expect(v.state, PaperState.searching);
    }
  });

  test('a still receipt fires after the required frames', () {
    final d = PaperDetector(requiredFrames: 5);
    PaperVerdict? last;
    for (var i = 0; i < 5; i++) {
      last = d.feed(width: 640, height: 480, luma: frame(paper: 200, table: 60));
    }
    expect(last!.state, PaperState.ready);
    expect(last.progress, 1);
  });

  test('a moving receipt restarts the count', () {
    final d = PaperDetector(requiredFrames: 4, maxMotion: 6);
    d.feed(width: 640, height: 480, luma: frame(paper: 200, table: 60));
    d.feed(width: 640, height: 480, luma: frame(paper: 200, table: 60));
    final moved = d.feed(width: 640, height: 480, luma: frame(paper: 200, table: 60, shift: -30));
    expect(moved.state, PaperState.moving);
    expect(d.stableFrames, 0);
  });

  test('paper needs contrast with its surroundings, not just brightness', () {
    final d = PaperDetector();
    final v = d.feed(width: 640, height: 480, luma: frame(paper: 200, table: 190));
    expect(v.state, PaperState.searching, reason: 'a white wall behind is not a receipt');
  });

  test('a portrait frame reads the guide along its long axis', () {
    final d = PaperDetector(requiredFrames: 1);
    final v = d.feed(
      width: 480,
      height: 640,
      luma: (x, y) {
        final l = y / 639;
        return l >= 0.14 && l <= 0.86 ? 210 : 50;
      },
    );
    expect(v.state, PaperState.ready);
  });
}
