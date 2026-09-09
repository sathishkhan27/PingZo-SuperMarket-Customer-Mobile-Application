import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/product_model.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product_provider.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryFilter;
  const ProductListScreen({Key? key, this.categoryFilter = 'ALL'}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = "";
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryFilter;
  }

  List<ProductModel> _getFilteredProducts(ProductProvider provider) {
    return provider.getFilteredProducts(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  List<String> _getCategories(ProductProvider provider) {
    return ['ALL', ...provider.categories];
  }

  void _showProductDetailModal(ProductModel product, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BentoTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(product.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: BentoTheme.pingzoGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text("⭐ ${product.rating}", style: const TextStyle(color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("${product.unit} • ${product.categoryName}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                product.isVegetableOrFruit
                    ? "Farm-fresh organic quality sourced directly from local farmers. 0% SGST/CGST tax."
                    : "Premium packaged food item processed with strict quality checks.",
                style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("₹${product.originalPrice.toInt()}", style: const TextStyle(color: BentoTheme.textSecondary, decoration: TextDecoration.lineThrough, fontSize: 12)),
                      Text("₹${product.discountPrice.toInt()}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BentoTheme.pingzoGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      cart.addToCart(product);
                      Navigator.pop(context);
                    },
                    child: const Text("Add to Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final filteredProducts = _getFilteredProducts(productProvider);
    final categories = _getCategories(productProvider);

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Supermarket Products", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BentoTheme.bentoCardDecoration(),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search_rounded, color: BentoTheme.pingzoGreen),
                      hintText: "Search groceries, veggies, milk...",
                      hintStyle: TextStyle(color: BentoTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      bool isSel = _selectedCategory.toLowerCase() == cat.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? BentoTheme.pingzoGreen : BentoTheme.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? BentoTheme.pingzoGreen : Colors.white10),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : BentoTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: BentoTheme.pingzoGreen))
                : filteredProducts.isEmpty
                    ? const Center(child: Text("No products found", style: TextStyle(color: BentoTheme.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, idx) {
                          final p = filteredProducts[idx];
                          return GestureDetector(
                            onTap: () => _showProductDetailModal(p, cart),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BentoTheme.bentoCardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(p.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(p.unit, style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondary)),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("₹${p.originalPrice.toInt()}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 11, decoration: TextDecoration.lineThrough)),
                                          Text("₹${p.discountPrice.toInt()}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_rounded, color: BentoTheme.pingzoGreen, size: 28),
                                        onPressed: () => cart.addToCart(p),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
