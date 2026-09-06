import 'package:hive_ce/hive.dart';

import '../../hive_registrar.g.dart';

class AdaptersController {
  /// Adapter registration comes from the generated registrar so a new
  /// `@HiveType` can never be missed here.
  ///
  /// Boxes are deliberately *not* opened at startup any more: their names are
  /// scoped to the signed-in account (see [UserScope]), which is not known
  /// until auth resolves.
  static Future<void> registerAdapters() async {
    Hive.registerAdapters();
  }
}
