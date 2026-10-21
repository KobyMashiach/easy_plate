import 'dart:io';
import 'dart:typed_data';

import 'package:easy_plate/core/services/image_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  final service = ImageStorageService();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('image_storage_test');
    service.useDirectoryForTest(dir);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('an unseen file is found off the build path, then known', () async {
    // Written behind the service's back, so no set knows the name.
    File('${dir.path}/a.jpg').writeAsBytesSync([1]);

    // The build-path read does not stat: it answers from what it knows.
    expect(service.pathFor('a.jpg'), isNull);
    expect(await service.resolve('a.jpg'), '${dir.path}/a.jpg');
    expect(service.pathFor('a.jpg'), '${dir.path}/a.jpg');
  });

  test('a name with no file stays absent', () async {
    expect(service.pathFor('missing.jpg'), isNull);
    expect(await service.resolve('missing.jpg'), isNull);
    expect(service.pathFor('missing.jpg'), isNull);
  });

  test('a write during the check wins over its answer', () async {
    expect(service.pathFor('b.jpg'), isNull); // check starts: no file yet
    await service.storeBytes('b.jpg', Uint8List.fromList([1]));
    expect(await service.resolve('b.jpg'), '${dir.path}/b.jpg');
  });

  test('delete removes a file the service had not met yet', () async {
    final file = File('${dir.path}/c.jpg')..writeAsBytesSync([1]);
    await service.delete('c.jpg');
    expect(file.existsSync(), isFalse);
    expect(service.pathFor('c.jpg'), isNull);
  });

  test('the listing, run after the first frame, makes files known', () async {
    File('${dir.path}/d.jpg').writeAsBytesSync([1]);
    await service.listDirectory();
    // Known without a check: answered synchronously.
    expect(service.pathFor('d.jpg'), '${dir.path}/d.jpg');
    // Once per session.
    File('${dir.path}/e.jpg').writeAsBytesSync([1]);
    await service.listDirectory();
    expect(service.pathFor('e.jpg'), isNull);
    expect(await service.resolve('e.jpg'), '${dir.path}/e.jpg');
  });

  test('a delete before the listing lands is not undone by it', () async {
    File('${dir.path}/f.jpg').writeAsBytesSync([1]);
    await service.storeBytes('f.jpg', Uint8List.fromList([1]));
    await service.delete('f.jpg');
    // Simulates an entry the listing read before the file went.
    File('${dir.path}/f.jpg').writeAsBytesSync([1]);
    await service.listDirectory();
    expect(service.pathFor('f.jpg'), isNull);
  });

  group('a name another account wrote', () {
    test('cannot climb out of the image directory', () async {
      final outside = File(
        '${dir.parent.path}/victim_${dir.uri.pathSegments.where((p) => p.isNotEmpty).last}.hive',
      )..writeAsBytesSync([7]);
      addTearDown(() {
        if (outside.existsSync()) outside.deleteSync();
      });
      final name = '../${outside.uri.pathSegments.last}';

      expect(
        await service.storeBytes(name, Uint8List.fromList([1, 2])),
        isNull,
      );
      expect(outside.readAsBytesSync(), [7]);
      expect(service.pathFor(name), isNull);
      expect(await service.resolve(name), isNull);
      await service.delete(name);
      expect(outside.existsSync(), isTrue);
    });

    test('plain names pass, separators and dot names do not', () {
      expect(ImageStorageService.isSafeName('3f2a-11.jpg'), isTrue);
      expect(ImageStorageService.isSafeName('receipt_ab_0.pdf'), isTrue);
      for (final bad in [
        '',
        '.',
        '..',
        '.hidden',
        'a/b.jpg',
        r'a\b.jpg',
        '/etc/passwd',
        'a\u0000.jpg',
        'x' * 201,
      ]) {
        expect(ImageStorageService.isSafeName(bad), isFalse, reason: bad);
      }
    });
  });
}
