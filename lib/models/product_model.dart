enum ProductCategory {
  rawHoney,
  processedHoney,
  combHoney,
  organicHoney,
  specialtyHoney;

  String get label => switch (this) {
        ProductCategory.rawHoney => 'Raw Honey',
        ProductCategory.processedHoney => 'Processed Honey',
        ProductCategory.combHoney => 'Comb Honey',
        ProductCategory.organicHoney => 'Organic Honey',
        ProductCategory.specialtyHoney => 'Specialty Honey',
      };
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.batchId,
    required this.batchCode,
    required this.sellerId,
    required this.sellerName,
    required this.origin,
    required this.priceInr,
    required this.weightGrams,
    required this.quantityAvailable,
    required this.category,
    required this.isVerified,
    required this.harvestDate,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String batchId;
  final String batchCode;
  final String sellerId;
  final String sellerName;
  final String origin;
  final double priceInr;
  final int weightGrams;
  final int quantityAvailable;
  final ProductCategory category;
  final bool isVerified;
  final DateTime harvestDate;
  final String? imageUrl;

  String get formattedPrice => '₹${priceInr.toStringAsFixed(0)}';
  String get formattedWeight =>
      weightGrams >= 1000 ? '${weightGrams / 1000} kg' : '$weightGrams g';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      batchId: json['batch_id'] as String,
      batchCode: json['batch_code'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String,
      origin: json['origin'] as String,
      priceInr: (json['price_inr'] as num).toDouble(),
      weightGrams: json['weight_grams'] as int,
      quantityAvailable: json['quantity_available'] as int,
      category: ProductCategory.values.byName(json['category'] as String),
      isVerified: json['is_verified'] as bool,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'batch_id': batchId,
        'batch_code': batchCode,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'origin': origin,
        'price_inr': priceInr,
        'weight_grams': weightGrams,
        'quantity_available': quantityAvailable,
        'category': category.name,
        'is_verified': isVerified,
        'harvest_date': harvestDate.toIso8601String(),
        'image_url': imageUrl,
      };
}

class SellerListingStats {
  const SellerListingStats({
    required this.activeListings,
    required this.soldProducts,
    required this.totalRevenue,
  });

  final int activeListings;
  final int soldProducts;
  final double totalRevenue;
}
