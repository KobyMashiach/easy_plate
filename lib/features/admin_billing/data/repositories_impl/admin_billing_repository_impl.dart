import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/admin_billing_repository.dart';
import '../datasources/admin_billing_remote_datasource.dart';
import '../datasources/admin_users_remote_datasource.dart';

class AdminBillingRepositoryImpl implements AdminBillingRepository {
  final AdminBillingRemoteDataSource remoteDataSource;
  final AdminUsersRemoteDataSource usersDataSource;

  AdminBillingRepositoryImpl({
    required this.remoteDataSource,
    required this.usersDataSource,
  });

  @override
  Future<AdminBillingSnapshot> load() => remoteDataSource.load();

  @override
  Future<void> setPremium(
    String uid,
    bool premium, {
    DateTime? from,
    DateTime? until,
  }) => remoteDataSource.setPremium(uid, premium, from: from, until: until);

  @override
  Future<void> releaseLock(String uid) => remoteDataSource.releaseLock(uid);

  @override
  Future<void> disableAccount(String uid, String message) =>
      usersDataSource.disable(uid, message);

  @override
  Future<void> enableAccount(String uid) => usersDataSource.enable(uid);

  @override
  Future<void> deleteAccount(String uid) => usersDataSource.delete(uid);

  @override
  Future<void> notifyAccount(
    String uid, {
    required String title,
    required String body,
  }) => usersDataSource.notify(uid, title: title, body: body);

  @override
  Future<BroadcastResult> notifyAll({
    required String title,
    required String body,
  }) => usersDataSource.notifyAll(title: title, body: body);
}
