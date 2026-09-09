import 'package:flutter/material.dart';
import '../core/state/base_provider.dart';
import '../models/banner_model.dart';
import '../services/api_service.dart';

import '../services/color_extractor_service.dart';

class BannerProvider extends BaseProvider {
  List<BannerModel> _banners = [];

  List<BannerModel> get banners => _banners;

  BannerProvider() {
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    await runAsync(() async {
      try {
        final data = await ApiService.getBanners();
        if (data.isNotEmpty) {
          _banners = data;
        } else {
          _banners = _getDefaultBanners();
        }
      } catch (e) {
        debugPrint("Error fetching banners: $e");
        _banners = _getDefaultBanners();
      }

      for (final banner in _banners) {
        if (banner.imageUrl.isNotEmpty) {
          ColorExtractorService.extractDominantColor(banner.imageUrl).then((color) {
            if (color != null) {
              banner.extractedColor = color;
              notifyListeners();
            }
          });
        }
      }
    });
  }

  List<BannerModel> _getDefaultBanners() {
    return [
      BannerModel(
        id: "b1",
        title: "INDEPENDENCE DAY SALE",
        subtitle: "Up to 60% OFF on Fresh Fruits & Vegetables",
        imageUrl: "https://picsum.photos/seed/vegbanner/800/400",
        targetCategory: "Fresh Vegetables",
        linkedCouponCode: "FRESH25",
        badgeText: "FRESH DEAL",
      ),
      BannerModel(
        id: "b2",
        title: "SUPERMARKET EXPRESS",
        subtitle: "Guaranteed 6-Min Delivery on Dairy & Staples",
        imageUrl: "https://picsum.photos/seed/dairybanner/800/400",
        targetCategory: "Dairy & Milk",
        linkedCouponCode: "PINGZO100",
        badgeText: "INSTANT",
      ),
      BannerModel(
        id: "b3",
        title: "BLOOM ORGANIC SPECIALS",
        subtitle: "Handpicked Organic Fruits Direct From Farm",
        imageUrl: "https://picsum.photos/seed/fruitbanner/800/400",
        targetCategory: "Fresh Fruits",
        linkedCouponCode: "EXPRESS",
        badgeText: "ORGANIC",
      ),
    ];
  }

  Future<void> refresh() async {
    await fetchBanners();
  }
}
