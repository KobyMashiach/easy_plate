import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_datasource.dart';
import '../datasources/pricing_sync_remote_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardRemoteDataSource remoteDataSource;
  final PricingSyncRemoteDataSource pricingSync;

  AdminDashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.pricingSync,
  });

  @override
  Future<PricingSyncResult> syncPricingFromGoogle() => pricingSync.sync();

  @override
  Future<DashboardOverview> load(DashboardPeriod period) =>
      remoteDataSource.load(period);

  @override
  Future<AiPricing> loadPricing() => remoteDataSource.loadPricing();

  @override
  Future<void> savePricing(AiPricing pricing) =>
      remoteDataSource.savePricing(pricing);

  @override
  Future<UserAiUsage?> userUsage(String uid) => remoteDataSource.userUsage(uid);

  @override
  Future<List<AiCallEntity>> recentCalls(String uid, {int limit = 40}) =>
      remoteDataSource.recentCalls(uid, limit: limit);
}
