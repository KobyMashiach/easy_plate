import '../../../recipe_ingestion/data/datasources/recipe_ai_datasource.dart'
    show ReceiptPage;
import '../../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../entities/receipt_scan_entity.dart';

class ScanReceiptUseCase {
  final RecipeIngestionRepository repository;
  ScanReceiptUseCase(this.repository);

  Future<ReceiptScanEntity> call(List<ReceiptPage> pages) =>
      repository.scanReceipt(pages);
}
