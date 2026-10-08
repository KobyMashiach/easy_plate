import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../errors/app_exception.dart';
import '../utils/i18n/strings.g.dart';
import 'ai_auth_header.dart';
import 'http_calls.dart';

/// One Google image result, as the `imageSearch` function returns it.
class WebImageResult {
  final String url;
  final String thumbnail;
  final int? width;
  final int? height;
  final String title;
  final String source;

  const WebImageResult({
    required this.url,
    required this.thumbnail,
    required this.title,
    required this.source,
    this.width,
    this.height,
  });

  static WebImageResult? fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    final thumbnail = json['thumbnail'];
    return WebImageResult(
      url: url,
      thumbnail: thumbnail is String && thumbnail.isNotEmpty ? thumbnail : url,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? '',
      source: (json['source'] as String?) ?? '',
    );
  }
}

/// A page of ten, plus where the next one starts (null at the end).
class WebImagePage {
  final List<WebImageResult> items;
  final int? nextStart;

  const WebImagePage({required this.items, required this.nextStart});

  bool get hasMore => nextStart != null;

  static WebImagePage fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map((m) => WebImageResult.fromJson(Map<String, dynamic>.from(m)))
              .nonNulls
              .toList()
        : <WebImageResult>[];
    return WebImagePage(
      items: items,
      nextStart: (json['nextStart'] as num?)?.toInt(),
    );
  }
}

/// Thrown when the server says the search is not set up at all (no API key
/// or engine id), which the picker reports differently from a network blip.
class ImageSearchUnavailable implements Exception {
  const ImageSearchUnavailable();
}

/// Talks to the `imageSearch` function and fetches the picked picture.
///
/// Only meaningful behind the proxy: against Google directly there is no
/// server to hold the Custom Search key, and [isAvailable] says so, which
/// hides the option rather than offering a search that cannot run.
class ImageSearchClient {
  final HttpCalls _http;
  final Dio _downloader;

  ImageSearchClient({HttpCalls? http, Dio? downloader})
    : _http = http ?? HttpCalls(headerProvider: aiProxyAuthHeader),
      _downloader =
          downloader ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.bytes,
              // A few hosts refuse a bare client; a browser-looking one is
              // what the picture was served to when Google indexed it.
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
                'Accept': 'image/*,*/*;q=0.8',
              },
            ),
          );

  static bool get isAvailable => ApiConfig.usesProxy;

  /// Ten results from [start] (1-based, as Google counts).
  Future<WebImagePage> search(String query, {int start = 1}) async {
    final response = await _http.post(
      ApiConfig.imageSearchUrl,
      data: {
        'query': query,
        'start': start,
        'lang': LocaleSettings.currentLocale.languageCode,
      },
    );
    final body = response?.data;
    if (body is! Map) {
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'No results',
      );
    }
    return WebImagePage.fromJson(Map<String, dynamic>.from(body));
  }

  /// The picture itself, [thumbnail] when the host refuses the original.
  /// Null when neither can be had.
  Future<Uint8List?> download(WebImageResult result) async {
    for (final url in {result.url, result.thumbnail}) {
      final bytes = await _fetch(url);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }
    return null;
  }

  Future<Uint8List?> _fetch(String url) async {
    try {
      final response = await _downloader.get<List<int>>(url);
      final data = response.data;
      final type = response.headers.value('content-type') ?? '';
      // An HTML error page with a 200 is not a picture, whatever it is named.
      if (data == null || type.startsWith('text/html')) return null;
      return Uint8List.fromList(data);
    } catch (e) {
      debugPrint('Image download failed for $url: $e');
      return null;
    }
  }
}

/// Whether an [AppException] from [ImageSearchClient.search] is the server
/// saying the feature is not configured (503 with `not_configured`).
bool isImageSearchUnavailable(AppException e) =>
    e.type == AppErrorType.overloaded && e.message.contains('not_configured');
