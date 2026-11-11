import 'package:go_router/go_router.dart';

import '../../../core/features/feature_gate.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/utils/routing/routing.dart';
import '../domain/entities/ingestion_file.dart';

/// Routes a share that holds several recipes ([ShareIntentService.latestBulk])
/// to the bulk import screen. Called by the app's share listener once the
/// session is ready; true when there was such a share, handled or dropped,
/// so the caller does nothing more with it.
///
/// With the bulk import switched off, a share of several links goes where
/// it always went — the single form, as text — and a chat export, which
/// had nowhere to go before, is explained and dropped.
bool deliverBulkShare(GoRouter router) {
  final service = ShareIntentService();
  final bulk = service.latestBulk.value;
  if (bulk == null) return false;
  service.clearBulk();
  if (!FeaturesFlags.bulkImport.isEnabled) {
    final text = bulk.fallbackText;
    if (text != null) {
      // Through the single-share path, with its own flag checks.
      service.latest.value = IngestionLaunch(
        channel: IngestionLaunch.channelForText(text),
        text: text,
      );
    } else {
      final context = router.routerDelegate.navigatorKey.currentContext;
      if (context != null) explainAccess(context, FeaturesFlags.bulkImport);
    }
    return true;
  }
  if (!FeaturesFlags.shareIn.isEnabled) {
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context != null) explainAccess(context, FeaturesFlags.shareIn);
    return true;
  }
  router.pushNamed(Routing.bulkImport, extra: bulk);
  return true;
}
