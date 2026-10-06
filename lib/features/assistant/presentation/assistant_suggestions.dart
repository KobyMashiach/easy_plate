import 'dart:math';

import '../../../core/utils/i18n/strings.g.dart';

/// Opening prompts for the chat, drawn from templates and fillers in the
/// current language (hundreds of distinct sentences), a fresh handful per
/// conversation so the chips never read the same twice.
abstract class AssistantSuggestions {
  static List<String> pick(int count, {Random? random}) {
    final rng = random ?? Random();
    final s = t.assistant.suggest;
    final pools = <String, List<String>>{
      'food': s.food,
      'dish': s.dish,
      'day': s.day,
      'meal': s.meal,
      'n': s.n,
      'site': s.site,
      'book': s.book,
      'diet': s.diet,
    };
    final templates = [...s.templates]..shuffle(rng);
    final out = <String>[];
    for (final template in templates) {
      if (out.length >= count) break;
      var text = template;
      String? firstFood;
      for (final entry in pools.entries) {
        final key = '{${entry.key}}';
        if (text.contains(key)) {
          final value = entry.value[rng.nextInt(entry.value.length)];
          if (entry.key == 'food') firstFood = value;
          text = text.replaceAll(key, value);
        }
      }
      if (text.contains('{food2}')) {
        final others = s.food.where((f) => f != firstFood).toList();
        text = text.replaceAll('{food2}', others[rng.nextInt(others.length)]);
      }
      if (!out.contains(text)) out.add(text);
    }
    return out;
  }
}
