import 'package:easy_plate/features/price_book/data/datasources/community_prices_remote_datasource.dart';
import 'package:easy_plate/features/price_book/data/datasources/price_records_local_datasource.dart';
import 'package:easy_plate/features/price_book/data/repositories_impl/price_book_repository_impl.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Local extends Mock implements PriceRecordsLocalDataSource {}

class _Remote extends Mock implements CommunityPricesRemoteDataSource {}

void main() {
  test('a failed lookup is not kept as "no data"', () async {
    final remote = _Remote();
    final repo = PriceBookRepositoryImpl(
      localDataSource: _Local(),
      remoteDataSource: remote,
    );
    when(
      () => remote.lookup('milk'),
    ).thenAnswer((_) async => throw StateError('offline'));
    await expectLater(repo.communityPrice('milk'), throwsStateError);

    const answer = CommunityPriceEntity(
      normalizedName: 'milk',
      median: 6,
      average: 6,
      count: 3,
    );
    when(() => remote.lookup('milk')).thenAnswer((_) async => answer);
    expect(await repo.communityPrice('milk'), same(answer));
    // Now cached: no third read.
    expect(await repo.communityPrice('milk'), same(answer));
    verify(() => remote.lookup('milk')).called(2);
  });
}
