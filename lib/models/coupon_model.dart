class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discountPercentage;
  final double maxDiscountAmount;
  final double minOrderAmount;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.maxDiscountAmount,
    required this.minOrderAmount,
  });

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderAmount) return 0.0;
    double discount = (subtotal * discountPercentage) / 100.0;
    if (discount > maxDiscountAmount) return maxDiscountAmount;
    return discount;
  }
}
