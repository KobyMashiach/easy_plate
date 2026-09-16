import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/admin_billing_repository.dart';
import '../datasources/admin_billing_remote_datasource.dart';

class AdminBillingRepositoryImpl implements AdminBillingRepository {
  final AdminBillingRemoteDataSource remoteDataSource;

  AdminBillingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminBillingSnapshot> load() => remoteDataSource.load();

  @override
  Future<void> setPremium(String uid, bool premium) =>
      remoteDataSource.setPremium(uid, premium);

  @override
  Future<void> releaseLock(String uid) => remoteDataSource.releaseLock(uid);
}
