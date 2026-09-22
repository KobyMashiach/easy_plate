import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Asks the adminUsers function to refresh `admin_config/pricing` from the
/// Cloud Billing catalog. The catalog needs a Google credential the app
/// does not hold, which is why it runs server-side.
abstract class PricingSyncRemoteDataSource {
  Future<PricingSyncResult> sync();
}

class PricingSyncHttpDataSource implements PricingSyncRemoteDataSource {
  final HttpCalls _calls;

  PricingSyncHttpDataSource({HttpCalls? calls})
    : _calls =
          calls ??
          HttpCalls(
            baseUrl: ApiConfig.adminUsersUrl,
            headerProvider: aiProxyAuthHeader,
          );

  @override
  Future<PricingSyncResult> sync() async {
    if (!ApiConfig.usesProxy) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'Price sync needs the Cloud Functions deploy (AI_BASE_URL)',
      );
    }
    final response = await _calls.post('', data: {'action': 'syncPricing'});
    final data = response?.data;
    if (data is! Map<String, dynamic>) {
      throw const AppException(AppErrorType.parsingFailed);
    }
    return PricingSyncResult(
      matched: (data['matched'] as num?)?.toInt() ?? 0,
      models: [
        for (final m in (data['models'] as List?) ?? const []) m.toString(),
      ],
      service: (data['service'] as String?) ?? '',
    );
  }
}
