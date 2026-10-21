import 'dart:io';

import 'package:easy_plate/core/services/image_storage_service.dart';
import 'package:easy_plate/core/widgets/clay/clay_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('clay_image_test');
    ImageStorageService().useDirectoryForTest(dir);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Widget host(String? fileName) => MaterialApp(
    home: SizedBox(
      width: 100,
      height: 100,
      child: ClayImage(fileName: fileName),
    ),
  );

  testWidgets(
    'a photo on disk the listing has not reached never shows as missing',
    (tester) async {
      File('${dir.path}/p.jpg').writeAsBytesSync([1, 2, 3]);
      // Real I/O: the check is a real stat, so the widget is built where
      // real futures complete.
      await tester.runAsync(() async {
        await tester.pumpWidget(host('p.jpg'));
        // First frame: the check is out, the medallion is not drawn.
        expect(find.byIcon(Icons.restaurant_menu_rounded), findsNothing);
        expect(find.byType(Image), findsNothing);
        await ImageStorageService().resolve('p.jpg');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsNothing);
    },
  );

  testWidgets('a name with no file ends on the medallion', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(host('gone.jpg'));
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsNothing);
      await ImageStorageService().resolve('gone.jpg');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
  });

  testWidgets('no file name shows the medallion at once', (tester) async {
    await tester.pumpWidget(host(null));
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
  });
}
