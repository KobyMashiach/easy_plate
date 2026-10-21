import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_plate/core/network/image_search_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late String base;
  // Bytes served per path, with a Content-Length header.
  final served = <String, int>{};

  setUp(() async {
    served.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://${server.address.host}:${server.port}';
    server.listen((request) async {
      final size = served[request.uri.path];
      if (size == null) {
        request.response.statusCode = 404;
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.contentLength = size;
      request.response.add(Uint8List(size));
      try {
        await request.response.close();
      } catch (_) {
        // Refused on the header alone: the client hung up.
      }
    });
  });

  tearDown(() => server.close(force: true));

  WebImageResult result(String url, String thumb) =>
      WebImageResult(url: url, thumbnail: thumb, title: '', source: '');

  test('a picture under the cap comes back whole', () async {
    served['/ok'] = 300 * 1024;
    final client = ImageSearchClient(maxDownloadBytes: 1024 * 1024);
    final bytes = await client.download(result('$base/ok', '$base/ok'));
    expect(bytes, isNotNull);
    expect(bytes!.length, 300 * 1024);
  });

  test(
    'a declared length over the cap is refused, and the thumbnail used',
    () async {
      served['/big'] = 4 * 1024 * 1024;
      served['/thumb'] = 10 * 1024;
      final client = ImageSearchClient(maxDownloadBytes: 1024 * 1024);
      final bytes = await client.download(result('$base/big', '$base/thumb'));
      expect(bytes!.length, 10 * 1024);
    },
  );

  test(
    'a body with no length is cut, and the connection dropped, past the cap',
    () async {
      // A raw socket, so the test sees the client hang up: a body that would
      // never end unless the reader stops it.
      final raw = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final hungUp = Completer<void>();
      var sent = 0;
      raw.listen((socket) {
        var open = true;
        socket.listen(
          (_) {},
          onDone: () {
            open = false;
            if (!hungUp.isCompleted) hungUp.complete();
          },
          onError: (Object _) {
            open = false;
            if (!hungUp.isCompleted) hungUp.complete();
          },
        );
        socket.add(
          utf8.encode(
            'HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\n'
            'Connection: close\r\n\r\n',
          ),
        );
        () async {
          try {
            while (open && sent < 256 * 1024 * 1024) {
              socket.add(Uint8List(64 * 1024));
              sent += 64 * 1024;
              await socket.flush();
            }
          } catch (_) {
            // Written into a closed connection.
          }
          socket.destroy();
        }();
      });
      final url = 'http://127.0.0.1:${raw.port}/endless';
      final client = ImageSearchClient(maxDownloadBytes: 1024 * 1024);
      final bytes = await client.download(result(url, url));
      expect(bytes, isNull);
      await hungUp.future.timeout(const Duration(seconds: 5));
      expect(sent, lessThan(256 * 1024 * 1024));
      await raw.close();
    },
  );

  test('the default cap is 8 MB', () {
    expect(ImageSearchClient.defaultMaxDownloadBytes, 8 * 1024 * 1024);
  });
}
