import '../core/state/base_provider.dart';
import '../models/product_model.dart';
import '../models/coupon_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider extends BaseProvider {
  final List<CartItem> _items = [];
  CouponModel? _appliedCoupon;
  double _couponDiscountAmount = 0.0;
  String _selectedLocation = "Select Location";
  bool _isCheckingOut = false;

  List<CartItem> get items => _items;
  CouponModel? get appliedCoupon => _appliedCoupon;
  double get couponDiscountAmount => _couponDiscountAmount;
  String get selectedLocation => _selectedLocation;
  bool get isCheckingOut => _isCheckingOut;

  int get totalItemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + (i.product.discountPrice * i.quantity));

  // Indian GST Tax calculations (Vegetables 0%, Packaged Food 2.5% SGST + 2.5% CGST)
  double get totalSgst {
    double sgst = 0.0;
    for (var item in _items) {
      if (!item.product.isVegetableOrFruit) {
        sgst += (item.product.discountPrice * item.quantity) * (item.product.sgstPercentage / 100.0);
      }
    }
    return sgst;
  }

  double get totalCgst {
    double cgst = 0.0;
    for (var item in _items) {
      if (!item.product.isVegetableOrFruit) {
        cgst += (item.product.discountPrice * item.quantity) * (item.product.cgstPercentage / 100.0);
      }
    }
    return cgst;
  }

  // Free delivery threshold > ₹100
  double get deliveryFee => (subtotal > 100.0 || _items.isEmpty) ? 0.0 : 30.0;

  double get grossTotal {
    if (_items.isEmpty) return 0.0;
    double total = (subtotal - _couponDiscountAmount) + totalSgst + totalCgst + deliveryFee;
    return total < 0 ? 0.0 : total;
  }

  void setLocation(String loc) {
    _selectedLocation = loc;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    int index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    reevaluateCoupon();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    int index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
    }
    reevaluateCoupon();
    notifyListeners();
  }

  void applyCoupon(CouponModel coupon) {
    if (subtotal < coupon.minOrderAmount) {
      return;
    }
    _appliedCoupon = coupon;
    _couponDiscountAmount = coupon.calculateDiscount(subtotal);
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponDiscountAmount = 0.0;
    notifyListeners();
  }

  void reevaluateCoupon() {
    if (_appliedCoupon != null) {
      if (subtotal < _appliedCoupon!.minOrderAmount) {
        removeCoupon();
      } else {
        _couponDiscountAmount = _appliedCoupon!.calculateDiscount(subtotal);
      }
    }
  }

  int getQuantity(String productId) {
    int index = _items.indexWhere((i) => i.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Set checkout busy state (for checkout button spinner).
  void setCheckingOut(bool value) {
    _isCheckingOut = value;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _couponDiscountAmount = 0.0;
    notifyListeners();
  }
}
