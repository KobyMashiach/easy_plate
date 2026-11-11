import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/grocery_voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceGroceryItem item(
  String name, [
  double amount = 1,
  MeasurementUnit unit = MeasurementUnit.unit,
]) => VoiceGroceryItem(name: name, amount: amount, unit: unit);

void main() {
  List<VoiceGroceryItem> p(String s) => GroceryVoiceParser.parse(s);

  test('empty input', () {
    expect(p(''), isEmpty);
    expect(p('  ,  and '), isEmpty);
  });

  group('English', () {
    test('commas, and, number words and packages', () {
      expect(p('milk, eggs and two packs of bread'), [
        item('milk'),
        item('eggs'),
        item('bread', 2),
      ]);
    });

    test('digits, glued units, a dozen, one and a half', () {
      expect(p('2 liters of milk, 500g butter'), [
        item('milk', 2, MeasurementUnit.liter),
        item('butter', 500, MeasurementUnit.gram),
      ]);
      expect(p('a dozen eggs'), [item('eggs', 12)]);
      expect(p('one and a half kilo of flour'), [
        item('flour', 1.5, MeasurementUnit.kilogram),
      ]);
    });

    test('drops a leading command and fillers', () {
      expect(p('add some cheese and tomatoes'), [
        item('cheese'),
        item('tomatoes'),
      ]);
    });
  });

  group('Hebrew', () {
    test('the ו prefix splits items', () {
      expect(p('חלב, ביצים ושתי חבילות לחם'), [
        item('חלב'),
        item('ביצים'),
        item('לחם', 2),
      ]);
      expect(p('עגבניות מלפפונים ובצל'), [
        item('עגבניות מלפפונים'),
        item('בצל'),
      ]);
    });

    test('words that start with ו are kept', () {
      expect(p('וניל ושוקולד'), [item('וניל'), item('שוקולד')]);
      expect(p('תמצית וניל'), [item('תמצית וניל')]);
      expect(p('וודקה'), [item('וודקה')]);
    });

    test('quantities: half, and a half, number after the name, units', () {
      expect(p('חצי קילו גבינה'), [
        item('גבינה', 0.5, MeasurementUnit.kilogram),
      ]);
      expect(p('קילו וחצי עגבניות'), [
        item('עגבניות', 1.5, MeasurementUnit.kilogram),
      ]);
      expect(p('לחם אחד'), [item('לחם')]);
      expect(p('שלושה בקבוקי מים'), [item('מים', 3)]);
      expect(p('שני ליטר חלב'), [item('חלב', 2, MeasurementUnit.liter)]);
    });

    test('וגם and a leading command', () {
      expect(p('תוסיף חלב וגם קוטג׳'), [item('חלב'), item('קוטג׳')]);
    });
  });

  group('French', () {
    test('et, de, du, elision', () {
      expect(p('du lait, des œufs et deux paquets de pain'), [
        item('lait'),
        item('œufs'),
        item('pain', 2),
      ]);
      expect(p("un litre d'huile"), [item('huile', 1, MeasurementUnit.liter)]);
      expect(p('trois kilos de pommes'), [
        item('pommes', 3, MeasurementUnit.kilogram),
      ]);
    });

    test('a name with "de" inside keeps it', () {
      expect(p('pâte de coing'), [item('pâte de coing')]);
    });
  });

  group('Russian', () {
    test('и, number words and packages', () {
      expect(p('молоко, яйца и две пачки хлеба'), [
        item('молоко'),
        item('яйца'),
        item('хлеба', 2),
      ]);
      expect(p('пол литра сливок'), [
        item('сливок', 0.5, MeasurementUnit.liter),
      ]);
      expect(p('купи три кг картошки'), [
        item('картошки', 3, MeasurementUnit.kilogram),
      ]);
    });
  });

  group('Arabic', () {
    test('the و prefix, numbers and duals', () {
      expect(p('حليب وبيض واثنين خبز'), [
        item('حليب'),
        item('بيض'),
        item('خبز', 2),
      ]);
      expect(p('علبتين حمص'), [item('حمص', 2)]);
      expect(p('كيلو طماطم'), [
        item('طماطم', 1, MeasurementUnit.kilogram),
      ]);
    });

    test('words that start with و are kept; Arabic comma splits', () {
      expect(p('ورق عنب، أرز'), [item('ورق عنب'), item('أرز')]);
    });
  });
}
