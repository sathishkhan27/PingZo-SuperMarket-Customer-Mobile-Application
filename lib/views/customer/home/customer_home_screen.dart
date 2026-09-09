import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingzo_mobile/models/order_model.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/product_model.dart';
import '../../../models/banner_model.dart';
import '../../../services/cart_provider.dart';
import '../../../services/order_provider.dart';
import '../../../services/product_provider.dart';
import '../../../services/banner_provider.dart';
import '../../../services/location_provider.dart';
import '../../../services/color_extractor_service.dart';
import '../../location/location_map_picker_screen.dart';
import '../products/product_list_screen.dart';
import '../cart_checkout/cart_checkout_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../order_tracking/live_order_tracking_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../../services/notification_provider.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  String _selectedBuyAgainCategory = "ALL";
  
  final PageController _bannerPageController = PageController();
  int _activeBannerIndex = 0;
  Timer? _homeOrderPollTimer;

  final Set<String> _wishlistedProductIds = {};

  @override
  void initState() {
    super.initState();
    _bannerPageController.addListener(() {
      if (_bannerPageController.hasClients && _bannerPageController.page != null) {
        final currentRoundPage = _bannerPageController.page!.round();
        if (currentRoundPage != _activeBannerIndex) {
          setState(() {
            _activeBannerIndex = currentRoundPage;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.fetchProducts();
      final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
      bannerProvider.fetchBanners();
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.loadLocationData();
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.fetchOrders();

      // Poll active order state every 4s for instant delivery partner updates
      _homeOrderPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final orderProv = Provider.of<OrderProvider>(context, listen: false);
        final active = orderProv.activeOrder;
        if (active != null && active.orderStatus != 'DELIVERED' && active.orderStatus != 'CANCELLED') {
          orderProv.fetchOrderById(active.id);
        }
      });
    });
  }

  @override
  void dispose() {
    _homeOrderPollTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final activeOrder = orderProv.activeOrder;
    final productProvider = Provider.of<ProductProvider>(context);
    final bannerProvider = Provider.of<BannerProvider>(context);

    // Dynamic AppBar / Header background color based on active banner
    const defaultHeaderColor = Color(0xFF3897F0);
    Color currentAppBarColor = defaultHeaderColor;
    if (bannerProvider.banners.isNotEmpty) {
      final safeIndex = _activeBannerIndex.clamp(0, bannerProvider.banners.length - 1);
      currentAppBarColor = bannerProvider.banners[safeIndex].getColorForIndex(safeIndex);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: currentAppBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F8),
        body: Container(
          color: const Color(0xFFF3F5F8),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // 1 & 2 & 3. MERGED APPBAR & DYNAMIC BANNER HEADER CONTAINER
                  // Background color dynamically adapts to active banner, falling back to default blue!
                  _buildMergedAppBarAndBannerHeader(context, cart, bannerProvider, productProvider, currentAppBarColor),

                  // ─── ACTIVE LIVE ORDER TRACKING CARD ───
                  if (activeOrder != null && activeOrder.orderStatus != 'DELIVERED' && activeOrder.orderStatus != 'CANCELLED')
                    _buildActiveOrderBanner(context, activeOrder),

                  const SizedBox(height: 14),

                  // 6. Dynamic API Products Grid Section
                  _buildApiProductsGridSection(context, productProvider, cart),
                ],
              ),
            ),

            // Floating Delivery Bar & Pink Cart Button
            _buildFloatingActionOverlay(context, cart),
          ],
        ),
      ),
        ),

      // 5-Tab Zepto Bottom Navigation Bar
      bottomNavigationBar: _buildZeptoBottomNavBar(),
    ),
  );
}

  // ─────────────────────────────────────────────────────────────
  // 1. MERGED APPBAR & BANNER HEADER (Dynamic Color Matching Active Banner)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMergedAppBarAndBannerHeader(
    BuildContext context,
    CartProvider cart,
    BannerProvider bannerProvider,
    ProductProvider productProvider,
    Color appHeaderColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: appHeaderColor,
        //borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row: Location Section (Left) + Profile Icon (Right)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Location Section
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationMapPickerScreen()),
                      );
                      if (context.mounted) {
                        Provider.of<LocationProvider>(context, listen: false).loadLocationData();
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Delivery Location",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Consumer2<LocationProvider, CartProvider>(
                                      builder: (context, locProvider, cartProvider, _) {
                                        String locStr = locProvider.activeAddressTitle;
                                        if (locStr == "Select Location" &&
                                            cartProvider.selectedLocation.isNotEmpty &&
                                            cartProvider.selectedLocation != "Select Location") {
                                          locStr = cartProvider.selectedLocation;
                                        }
                                        return Text(
                                          locStr,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Notification Center Button
                Consumer<NotificationProvider>(
                  builder: (context, notifProv, _) {
                    final unread = notifProv.unreadCount;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (unread > 0)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: BentoTheme.accentRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Text(
                                    unread > 9 ? '9+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Profile Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar Embedded inside Header
          _buildZeptoSearchBar(context),

          const SizedBox(height: 14),

          // Dynamic Banner Carousel Slider
          _buildDynamicBannerCarousel(context, bannerProvider),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildZeptoSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Colors.black54, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search for "Apples, Rice, Oil..."',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            // Right Side Mini Promo Thumbnail (Salon at Home)
            Container(
              margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Salon at",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                      Text(
                        "Home",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      "https://picsum.photos/seed/salon/100/100",
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        color: const Color(0xFFFFECE6),
                        child: const Icon(Icons.spa, size: 18, color: Color(0xFFC2410C)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dynamic Banner Carousel Slider
  // ─────────────────────────────────────────────────────────────
  Widget _buildDynamicBannerCarousel(BuildContext context, BannerProvider bannerProvider) {
    if (bannerProvider.isLoading) {
      return Container(
        height: 185,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final banners = bannerProvider.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 185,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerPageController,
            itemCount: banners.length,
            onPageChanged: (idx) => setState(() => _activeBannerIndex = idx),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return ClipRRect(
                // borderRadius: BorderRadius.only(
                //   bottomLeft: Radius.circular(index == 0 ? 24 : 0),
                //   bottomRight: Radius.circular(index == banners.length - 1 ? 24 : 0),
                // ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(categoryFilter: banner.targetCategory),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 185,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (banner.imageUrl.isNotEmpty)
                          Image.network(
                            banner.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (frame != null && banner.extractedColor == null) {
                                ColorExtractorService.extractDominantColor(banner.imageUrl).then((col) {
                                  if (col != null && mounted) {
                                    setState(() {
                                      banner.extractedColor = col;
                                    });
                                  }
                                });
                              }
                              return child;
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF2563EB),
                              child: const Center(
                                child: Icon(Icons.stars_rounded, size: 60, color: Colors.white),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFF2563EB),
                            child: const Center(
                              child: Icon(Icons.stars_rounded, size: 60, color: Colors.white),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (banner.badgeText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    banner.badgeText,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              if (banner.title.isNotEmpty)
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              if (banner.subtitle.isNotEmpty)
                                Text(
                                  banner.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (idx) => Container(
                  width: _activeBannerIndex == idx ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _activeBannerIndex == idx ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. API-Based Category Deal Bento Grid
  // ─────────────────────────────────────────────────────────────
  Widget _buildApiCategoryBentoGrid(BuildContext context, ProductProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF3897F0))),
      );
    }

    final apiCategories = provider.categories;
    if (apiCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final deals = apiCategories.map((catName) {
      // String imgUrl = 'https://picsum.photos/seed/grocery/300/300';
      // final lower = catName.toLowerCase();
      // if (lower.contains('veg') || lower.contains('fruit')) {
      //   imgUrl = 'https://picsum.photos/seed/veggies/300/300';
      // } else if (lower.contains('dairy') || lower.contains('milk')) {
      //   imgUrl = 'https://picsum.photos/seed/milk/300/300';
      // } else if (lower.contains('grocery') || lower.contains('grain') || lower.contains('staple')) {
      //   imgUrl = 'https://picsum.photos/seed/staples/300/300';
      // } else if (lower.contains('snack') || lower.contains('beverage') || lower.contains('crav')) {
      //   imgUrl = 'https://picsum.photos/seed/snacks/300/300';
      // }
      return {
        'title': catName,
        'discount': 'Up to 50% Off',
        'imageUrl': '',
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: deals.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, idx) {
          final item = deals[idx];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductListScreen(categoryFilter: item['title'] as String),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['imageUrl'] as String,
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 28, color: Colors.grey),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['discount'] as String,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Offer Strip Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildOfferStripCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "1kg",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Buy any Rice, Oil from the selected list and get 1 Kg Sugar free",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 7. "Introducing bloom" Section (API Fruits & Veggies)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBloomSection(BuildContext context, ProductProvider provider, CartProvider cart) {
    final vegProducts = provider.products.where((p) => p.isVegetableOrFruit).toList();
    final displayList = vegProducts.isNotEmpty ? vegProducts : provider.products;

    if (provider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1E824C))),
      );
    }

    if (displayList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Introducing bloom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Introducing ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    "bloom",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3F6212),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                "Handpicked fresh fruits and vegetables",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4D7C0F),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal API Product Carousel
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayList.length,
            itemBuilder: (context, idx) {
              final product = displayList[idx];
              final isEven = idx % 2 == 0;
              final bgColor = isEven ? const Color(0xFFFFF0EB) : const Color(0xFFFCE7F3);

              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 120,
                          width: 130,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.apple, size: 40, color: Colors.red),
                            ),
                          ),
                        ),
                        // Floating Pink (+) Button
                        Positioned(
                          bottom: -8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              cart.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Added ${product.name} to cart"),
                                  duration: const Duration(milliseconds: 700),
                                  backgroundColor: const Color(0xFF1E824C),
                                ),
                              );
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE91E63), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFFE91E63),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price Badge & MRP
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E824C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "₹${product.discountPrice.toInt()}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (product.originalPrice > product.discountPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            "₹${product.originalPrice.toInt()}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product.originalPrice > product.discountPrice)
                      Text(
                        "₹${(product.originalPrice - product.discountPrice).toInt()} OFF",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E824C),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // See All ▸ Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductListScreen(categoryFilter: 'Fresh Vegetables'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "See All ",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Icon(Icons.arrow_right_rounded, color: Color(0xFF0F172A), size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. Dynamic API Products Grid Section
  // ─────────────────────────────────────────────────────────────
  Widget _buildApiProductsGridSection(BuildContext context, ProductProvider provider, CartProvider cart) {
    final apiCategories = ["All", ...provider.categories];

    final filteredProducts = provider.getFilteredProducts(
      category: _selectedBuyAgainCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Explore Products",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Dynamic API Categories Tab Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: apiCategories.map((cat) {
              final isSel = _selectedBuyAgainCategory.toLowerCase() == cat.toLowerCase();
              return GestureDetector(
                onTap: () => setState(() => _selectedBuyAgainCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? const Color(0xFFE91E63) : const Color(0xFFCBD5E1),
                      width: isSel ? 1.8 : 1.0,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                      color: isSel ? const Color(0xFFE91E63) : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // API Product Cards Grid
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF3897F0))),
          )
        else if (filteredProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text(
                "No products found",
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              itemBuilder: (context, idx) {
                final product = filteredProducts[idx];
                final qty = cart.getQuantity(product.id);
                final isWishlisted = _wishlistedProductIds.contains(product.id);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 98,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 30),
                              ),
                            ),
                          ),
                          // Wishlist Heart Icon
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isWishlisted) {
                                    _wishlistedProductIds.remove(product.id);
                                  } else {
                                    _wishlistedProductIds.add(product.id);
                                  }
                                });
                              },
                              child: Icon(
                                isWishlisted ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                color: isWishlisted ? const Color(0xFFE91E63) : Colors.black45,
                                size: 18,
                              ),
                            ),
                          ),
                          // Added Counter State / Pink (+) Button
                          Positioned(
                            bottom: -10,
                            right: 6,
                            child: qty > 0
                                ? Container(
                                    height: 28,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE91E63),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => cart.removeFromCart(product.id),
                                          child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            "$qty",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => cart.addToCart(product),
                                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => cart.addToCart(product),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Color(0xFFE91E63),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Price & Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E824C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "₹${product.discountPrice.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (product.originalPrice > product.discountPrice) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    "₹${product.originalPrice.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.black45,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (product.originalPrice > product.discountPrice)
                              Text(
                                "₹${(product.originalPrice - product.discountPrice).toInt()} OFF",
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E824C),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              product.unit,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // Active Order Tracker Banner (Real-time tracking on Home page)
  // ─────────────────────────────────────────────────────────────
  Widget _buildActiveOrderBanner(BuildContext context, dynamic activeOrder) {
    if (activeOrder == null) return const SizedBox.shrink();

    final orderId = activeOrder.id?.toString() ?? '';
    final rawStatus = activeOrder.orderStatus?.toString() ?? 'PLACED';
    final normalizedStatus = rawStatus.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
    final status = rawStatus.replaceAll('_', ' ');
    final eta = activeOrder.estimatedDeliveryEta?.toString() ?? '10-15 mins';

    final isAssigned = normalizedStatus == 'ASSIGNED' ||
        normalizedStatus == 'DRIVER_ASSIGNED' ||
        normalizedStatus == 'PARTNER_ASSIGNED' ||
        normalizedStatus == 'PICKED_UP' ||
        normalizedStatus == 'OUT_FOR_DELIVERY' ||
        normalizedStatus == 'ON_THE_WAY' ||
        normalizedStatus == 'DELIVERED';

    final hasDriver = (activeOrder.assignedDriverName != null &&
            activeOrder.assignedDriverName.toString().trim().isNotEmpty &&
            activeOrder.assignedDriverName.toString().trim().toLowerCase() != 'null') ||
        (activeOrder.assignedDriverId != null &&
            activeOrder.assignedDriverId.toString().trim().isNotEmpty &&
            activeOrder.assignedDriverId.toString().trim().toLowerCase() != 'null') ||
        isAssigned;

    final String? driverName = hasDriver
        ? (activeOrder.assignedDriverName != null &&
                activeOrder.assignedDriverName.toString().trim().isNotEmpty &&
                activeOrder.assignedDriverName.toString().trim().toLowerCase() != 'null'
            ? activeOrder.assignedDriverName.toString()
            : (activeOrder.assignedDriverId != null ? 'Delivery Partner #${activeOrder.assignedDriverId}' : 'Delivery Partner'))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveOrderTrackingScreen(
                orderId: orderId,
                initialOrder: activeOrder is OrderModel ? activeOrder : null,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BentoTheme.pingzoOrange.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: BentoTheme.pingzoOrange.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Live Pulse + Order # + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BentoTheme.pingzoGreenLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: BentoTheme.pingzoGreen),
                            SizedBox(width: 4),
                            Text(
                              "LIVE ORDER",
                              style: TextStyle(
                                color: BentoTheme.pingzoGreenDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "#$orderId",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.textSecondaryDark),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: BentoTheme.pingzoOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: BentoTheme.pingzoOrange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Main Info: Driver / Supermarket Icon + ETA + Description
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasDriver ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (hasDriver ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      hasDriver ? Icons.two_wheeler_rounded : Icons.storefront_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 14, color: BentoTheme.pingzoGreen),
                            const SizedBox(width: 2),
                            Text(
                              "Arriving in $eta",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: BentoTheme.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDriver
                              ? "$driverName is on the way"
                              : "Supermarket is packing your items",
                          style: const TextStyle(
                            fontSize: 12,
                            color: BentoTheme.textSecondaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: BentoTheme.pingzoGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TRACK",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: BentoTheme.borderLight),
              const SizedBox(height: 8),

              // Bottom Mini Bar: Delivery Person Info / OTP / Store
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          hasDriver ? Icons.person_pin_circle_rounded : Icons.storefront_rounded,
                          size: 14,
                          color: hasDriver ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasDriver
                                ? "Fleet Partner: $driverName (⭐ 4.9)"
                                : "Store: PingZo Hub (Packing)",
                            style: const TextStyle(
                              fontSize: 11,
                              color: BentoTheme.textPrimaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BentoTheme.bgLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Text(
                      "OTP: ${activeOrder.deliveryOtp ?? '4829'}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: BentoTheme.textPrimaryDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Floating Delivery Offer Bar & Pink Cart Button Overlay
  // ─────────────────────────────────────────────────────────────
  Widget _buildFloatingActionOverlay(BuildContext context, CartProvider cart) {
    if (cart.totalItemCount == 0) return const SizedBox.shrink();

    final remainingForFreeDelivery = (149 - cart.subtotal).clamp(0, 149).toInt();

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [


          // Pink Cart Action Button Pill
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartCheckoutScreen()),
              );
            },
            child: Container(
              height: 52,
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      cart.items.first.product.imageUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cart",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${cart.totalItemCount} ${cart.totalItemCount == 1 ? 'item' : 'items'}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Exact Zepto 5-Tab Bottom Navigation Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildZeptoBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductListScreen(categoryFilter: 'ALL')),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Categories",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
