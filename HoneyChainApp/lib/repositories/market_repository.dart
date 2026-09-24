import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import 'mock_data.dart';

abstract class MarketRepository {
  Future<List<ProductModel>> getProducts({String? query, ProductCategory? category});
  Future<ProductModel?> getProductById(String productId);
  Future<ProductModel?> getProductByBatchCode(String batchCode);
  Future<SellerListingStats> getSellerStats(String sellerId);
  Future<List<ProductModel>> getSellerListings(String sellerId);
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
  });
}

class MockMarketRepository implements MarketRepository {
  final List<ProductModel> _products = List.from(MockData.products);

  @override
  Future<List<ProductModel>> getProducts({
    String? query,
    ProductCategory? category,
  }) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    var results = List<ProductModel>.from(_products);
    if (category != null) {
      results = results.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.origin.toLowerCase().contains(q) ||
              p.batchCode.toLowerCase().contains(q))
          .toList();
    }
    return results;
  }

  @override
  Future<ProductModel?> getProductById(String productId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProductModel?> getProductByBatchCode(String batchCode) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return _products.firstWhere(
        (p) => p.batchCode.toUpperCase() == batchCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SellerListingStats> getSellerStats(String sellerId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    final listings = _products.where((p) => p.sellerId == sellerId).toList();
    return SellerListingStats(
      activeListings: listings.length,
      soldProducts: 127,
      totalRevenue: 78450,
    );
  }

  @override
  Future<List<ProductModel>> getSellerListings(String sellerId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return _products.where((p) => p.sellerId == sellerId).toList();
  }

  @override
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
  }) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    final product = ProductModel(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      batchId: batchId,
      batchCode: batchCode,
      sellerId: sellerId,
      sellerName: sellerName,
      origin: origin,
      priceInr: priceInr,
      weightGrams: weightGrams,
      quantityAvailable: quantityAvailable,
      category: category,
      isVerified: isVerified,
      harvestDate: harvestDate,
    );
    _products.insert(0, product);
    return product;
  }
}
