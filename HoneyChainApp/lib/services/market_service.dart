import '../models/product_model.dart';
import '../repositories/market_repository.dart';

class MarketService {
  MarketService({MarketRepository? repository})
      : _repository = repository ?? MockMarketRepository();

  final MarketRepository _repository;

  Future<List<ProductModel>> getProducts({
    String? query,
    ProductCategory? category,
  }) =>
      _repository.getProducts(query: query, category: category);

  Future<ProductModel?> getProductById(String productId) =>
      _repository.getProductById(productId);

  Future<ProductModel?> getProductByBatchCode(String batchCode) =>
      _repository.getProductByBatchCode(batchCode);

  Future<SellerListingStats> getSellerStats(String sellerId) =>
      _repository.getSellerStats(sellerId);

  Future<List<ProductModel>> getSellerListings(String sellerId) =>
      _repository.getSellerListings(sellerId);

  Future<ProductModel> createListing({
    required String sellerId,
    required String sellerName,
    required String batchId,
    required String batchCode,
    required String name,
    required String description,
    required double priceInr,
    required int weightGrams,
    required int quantityAvailable,
    required ProductCategory category,
    required String origin,
    required DateTime harvestDate,
    required bool isVerified,
  }) =>
      _repository.createListing(
        sellerId: sellerId,
        sellerName: sellerName,
        batchId: batchId,
        batchCode: batchCode,
        name: name,
        description: description,
        priceInr: priceInr,
        weightGrams: weightGrams,
        quantityAvailable: quantityAvailable,
        category: category,
        origin: origin,
        harvestDate: harvestDate,
        isVerified: isVerified,
      );
}
