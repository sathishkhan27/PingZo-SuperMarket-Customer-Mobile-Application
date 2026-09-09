class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double originalPrice;
  final double discountPrice;
  final int discountPercentage;
  final String unit;
  final String imageUrl;
  final int stockQuantity;
  final bool isVegetableOrFruit;
  final double sgstPercentage;
  final double cgstPercentage;
  final bool inStock;
  final double rating;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercentage,
    required this.unit,
    required this.imageUrl,
    required this.stockQuantity,
    required this.isVegetableOrFruit,
    required this.sgstPercentage,
    required this.cgstPercentage,
    required this.inStock,
    required this.rating,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final double origPrice = (json['originalPrice'] ?? json['mrp'] ?? json['price'] ?? 0.0).toDouble();
    final double discPrice = (json['discountPrice'] ?? json['sellingPrice'] ?? json['price'] ?? 0.0).toDouble();
    final int discPercentage = json['discountPercentage'] ??
        (origPrice > discPrice && origPrice > 0 ? (((origPrice - discPrice) / origPrice) * 100).round() : 0);
    final String catName = json['categoryName'] ?? json['category'] ?? 'General';
    final bool isVeg = json['isVegetableOrFruit'] ?? (catName.toLowerCase().contains('veg') || catName.toLowerCase().contains('fruit'));

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId']?.toString() ?? json['category'] ?? '',
      categoryName: catName,
      originalPrice: origPrice,
      discountPrice: discPrice > 0 ? discPrice : origPrice,
      discountPercentage: discPercentage,
      unit: json['unit'] ?? '1 unit',
      imageUrl: json['imageUrl'] ?? 'https://picsum.photos/seed/product/400/400',
      stockQuantity: json['stockQuantity'] ?? json['stockQty'] ?? 100,
      isVegetableOrFruit: isVeg,
      sgstPercentage: (json['sgstPercentage'] ?? (json['taxRate'] != null ? (json['taxRate'] / 2.0) : 2.5)).toDouble(),
      cgstPercentage: (json['cgstPercentage'] ?? (json['taxRate'] != null ? (json['taxRate'] / 2.0) : 2.5)).toDouble(),
      inStock: json['inStock'] ?? (json['stockQuantity'] == null || json['stockQuantity'] > 0),
      rating: (json['rating'] ?? 4.8).toDouble(),
    );
  }
}
