import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/hive/user_scope.dart';

/// One thing typed into the add-recipe box and sent: a search, a link, a
/// request — and the category it went in as.
@immutable
class RecentInput {
  final String text;
  final RecipeIngestionChannel channel;

  const RecentInput(this.text, this.channel);

  Map<String, String> toJson() => {'text': text, 'channel': channel.name};

  static RecentInput? fromJson(Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    final channel = RecipeIngestionChannel.values
        .where((c) => c.name == json['channel'])
        .firstOrNull;
    if (text is! String || text.isEmpty || channel == null) return null;
    return RecentInput(text, channel);
  }
}

/// The last few inputs of the add-recipe screen, offered as chips under the
/// box so a search or a link is one tap away the second time.
///
/// On this device only, per account through [UserScope] (wiped on sign-out
/// with every other scoped box); never synced. A pasted recipe is not kept —
/// only the short inputs: searches, links, requests.
class RecentInputsStore {
  static final RecentInputsStore instance = RecentInputsStore._();
  RecentInputsStore._();

  static const boxName = 'ingestionUiBox';
  static const _key = 'recentInputs';
  static const max = 3;

  /// Longer than this is a recipe, not something to type again.
  static const maxLength = 300;

  static const kept = {
    RecipeIngestionChannel.webSearch,
    RecipeIngestionChannel.urlScrape,
    RecipeIngestionChannel.socialVideo,
    RecipeIngestionChannel.aiRequest,
  };

  Future<List<RecentInput>> read() async {
    try {
      final box = await UserScope().open<String>(boxName);
      final raw = box.get(_key);
      if (raw == null) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list) ?RecentInput.fromJson(item),
      ].take(max).toList();
    } catch (e) {
      debugPrint('Recent inputs read failed: $e');
      return const [];
    }
  }

  /// Puts [text] first, dropping an older copy of it and anything past
  /// [max]. Inputs this store does not keep are ignored.
  Future<List<RecentInput>> add(
    String text,
    RecipeIngestionChannel channel,
  ) async {
    final value = text.trim();
    if (value.isEmpty || value.length > maxLength || !kept.contains(channel)) {
      return read();
    }
    final next = [
      RecentInput(value, channel),
      ...(await read()).where((r) => r.text != value),
    ].take(max).toList();
    await _write(next);
    return next;
  }

  Future<List<RecentInput>> remove(String text) async {
    final next = (await read()).where((r) => r.text != text).toList();
    await _write(next);
    return next;
  }

  Future<void> _write(List<RecentInput> inputs) async {
    try {
      final box = await UserScope().open<String>(boxName);
      await box.put(_key, jsonEncode([for (final r in inputs) r.toJson()]));
    } catch (e) {
      debugPrint('Recent inputs write failed: $e');
    }
  }
}
