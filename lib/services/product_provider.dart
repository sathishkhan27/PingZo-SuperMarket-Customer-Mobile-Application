import '../core/state/base_provider.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends BaseProvider {
  List<ProductModel> _products = [];
  List<String> _categories = [];

  List<ProductModel> get products => _products;
  List<String> get categories => _categories;

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    await runAsync(() async {
      try {
        final prods = await ApiService.getProducts();
        if (prods.isNotEmpty) {
          _products = prods;
        } else {
          _products = _getDefaultProducts();
        }
      } catch (e) {
        _products = _getDefaultProducts();
      }

      try {
        final apiCats = await ApiService.getCategories();
        if (apiCats.isNotEmpty) {
          _categories = apiCats;
        } else {
          _categories = _deriveCategories(_products);
        }
      } catch (_) {
        _categories = _deriveCategories(_products);
      }
    });
  }

  List<ProductModel> _getDefaultProducts() {
    return [
      ProductModel(
        id: '1',
        name: 'Aashirvaad Whole Wheat Atta 5kg',
        categoryId: '1',
        categoryName: 'Groceries & Grains',
        originalPrice: 310.0,
        discountPrice: 280.0,
        discountPercentage: 10,
        unit: '5kg Bag',
        imageUrl: 'https://picsum.photos/seed/atta/400/400',
        stockQuantity: 50,
        isVegetableOrFruit: false,
        sgstPercentage: 2.5,
        cgstPercentage: 2.5,
        inStock: true,
        rating: 4.8,
      ),
      ProductModel(
        id: '2',
        name: 'Fortune Sunlite Sunflower Oil 1L',
        categoryId: '1',
        categoryName: 'Groceries & Grains',
        originalPrice: 165.0,
        discountPrice: 145.0,
        discountPercentage: 12,
        unit: '1L Pouch',
        imageUrl: 'https://picsum.photos/seed/sunfloweroil/400/400',
        stockQuantity: 40,
        isVegetableOrFruit: false,
        sgstPercentage: 2.5,
        cgstPercentage: 2.5,
        inStock: true,
        rating: 4.7,
      ),
      ProductModel(
        id: '3',
        name: 'Amul Taaza Toned Milk 1L',
        categoryId: '2',
        categoryName: 'Dairy & Fresh',
        originalPrice: 54.0,
        discountPrice: 54.0,
        discountPercentage: 0,
        unit: '1 L',
        imageUrl: 'https://picsum.photos/seed/amulmilk/400/400',
        stockQuantity: 100,
        isVegetableOrFruit: false,
        sgstPercentage: 6.0,
        cgstPercentage: 6.0,
        inStock: true,
        rating: 4.9,
      ),
      ProductModel(
        id: '4',
        name: 'Fresh Organic Tomatoes 1kg',
        categoryId: '3',
        categoryName: 'Fresh Vegetables',
        originalPrice: 40.0,
        discountPrice: 32.0,
        discountPercentage: 20,
        unit: '1 kg',
        imageUrl: 'https://picsum.photos/seed/tomato/400/400',
        stockQuantity: 60,
        isVegetableOrFruit: true,
        sgstPercentage: 0.0,
        cgstPercentage: 0.0,
        inStock: true,
        rating: 4.6,
      ),
      ProductModel(
        id: '5',
        name: 'Madhur Refined Pure Sugar 1kg',
        categoryId: '1',
        categoryName: 'Groceries & Grains',
        originalPrice: 55.0,
        discountPrice: 48.0,
        discountPercentage: 12,
        unit: '1 Pack',
        imageUrl: 'https://picsum.photos/seed/sugar/400/400',
        stockQuantity: 80,
        isVegetableOrFruit: false,
        sgstPercentage: 2.5,
        cgstPercentage: 2.5,
        inStock: true,
        rating: 4.8,
      ),
      ProductModel(
        id: '6',
        name: 'Amul Pasteurised Butter 500g',
        categoryId: '2',
        categoryName: 'Dairy & Fresh',
        originalPrice: 275.0,
        discountPrice: 255.0,
        discountPercentage: 7,
        unit: '500g Pack',
        imageUrl: 'https://picsum.photos/seed/butter/400/400',
        stockQuantity: 30,
        isVegetableOrFruit: false,
        sgstPercentage: 6.0,
        cgstPercentage: 6.0,
        inStock: true,
        rating: 4.9,
      ),
    ];
  }

  /// Derive unique category names from the products list.
  List<String> _deriveCategories(List<ProductModel> products) {
    final seen = <String>{};
    final categories = <String>[];
    for (final p in products) {
      if (p.categoryName.isNotEmpty && seen.add(p.categoryName)) {
        categories.add(p.categoryName);
      }
    }
    return categories;
  }

  /// Filter products by category and search query.
  List<ProductModel> getFilteredProducts({
    String? category,
    String searchQuery = '',
  }) {
    return _products.where((p) {
      final matchesCategory = category == null ||
          category.isEmpty ||
          category == 'All' ||
          category == 'ALL' ||
          p.categoryName.toLowerCase().contains(category.toLowerCase()) ||
          category.toLowerCase().contains(p.categoryName.toLowerCase()) ||
          p.categoryId.toLowerCase().contains(category.toLowerCase());
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Pull-to-refresh support.
  Future<void> refresh() async {
    await fetchProducts();
  }
}
