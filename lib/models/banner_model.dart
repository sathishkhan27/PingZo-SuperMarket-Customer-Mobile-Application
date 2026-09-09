import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetCategory;
  final String linkedCouponCode;
  final String badgeText;
  final bool isActive;
  final Color? customColor;
  Color? extractedColor;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.targetCategory,
    required this.linkedCouponCode,
    this.badgeText = 'FLAT AMOUNT',
    this.isActive = true,
    this.customColor,
    this.extractedColor,
  });

  Color get effectiveColor => getColorForIndex(0);

  Color getColorForIndex(int index) {
    if (extractedColor != null) return extractedColor!;
    if (customColor != null) return customColor!;
    
    // Rich distinct vibrant palette for each slide
    const palette = [
      Color(0xFF3897F0), // 0: PingZo Vibrant Sky Blue
      Color(0xFF0D9488), // 1: Oceanic Teal
      Color(0xFF7C3AED), // 2: Royal Purple
      Color(0xFFEA580C), // 3: Vivid Sunset Orange
      Color(0xFF1E824C), // 4: Fresh Emerald Green
      Color(0xFFDB2777), // 5: Rose Pink
      Color(0xFF0284C7), // 6: Azure Blue
      Color(0xFFD97706), // 7: Warm Amber
    ];
    return palette[index % palette.length];
  }

  static String _formatImageUrl(dynamic rawUrl) {
    if (rawUrl == null) return '';
    String url = rawUrl.toString().trim();
    if (url.isEmpty) return '';

    try {
      final baseUri = Uri.tryParse(ApiClient.baseUrl);
      if (baseUri != null && baseUri.host.isNotEmpty) {
        if (url.contains('localhost:8080') || url.contains('127.0.0.1:8080')) {
          url = url
              .replaceAll('localhost:8080', '${baseUri.host}:${baseUri.port}')
              .replaceAll('127.0.0.1:8080', '${baseUri.host}:${baseUri.port}');
        } else if (url.contains('localhost') || url.contains('127.0.0.1')) {
          url = url
              .replaceAll('localhost', baseUri.host)
              .replaceAll('127.0.0.1', baseUri.host);
        }

        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
          if (url.startsWith('/')) {
            url = '$origin$url';
          } else {
            url = '$origin/$url';
          }
        }
      }
    } catch (_) {}

    return url;
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final rawImg = json['imageUrl'] ??
        json['image_url'] ??
        json['image'] ??
        json['bannerImage'] ??
        json['banner_image'] ??
        json['bannerImageUrl'] ??
        json['banner_image_url'] ??
        json['photo'] ??
        json['photoUrl'] ??
        json['photo_url'] ??
        json['url'] ??
        json['mediaUrl'] ??
        json['media_url'] ??
        json['file'] ??
        json['filePath'] ??
        json['file_path'] ??
        '';

    final rawStatus = json['status']?.toString().toUpperCase();
    final bool active = json['isActive'] ??
        json['is_active'] ??
        json['active'] ??
        (rawStatus == null || rawStatus == 'ACTIVE' || rawStatus == '1' || rawStatus == 'TRUE');

    return BannerModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['bannerId']?.toString() ??
          json['banner_id']?.toString() ??
          '',
      title: json['title'] ??
          json['name'] ??
          json['heading'] ??
          json['bannerTitle'] ??
          json['banner_title'] ??
          '',
      subtitle: json['subtitle'] ??
          json['sub_title'] ??
          json['subTitle'] ??
          json['description'] ??
          json['desc'] ??
          json['details'] ??
          json['tagline'] ??
          json['shortDescription'] ??
          json['short_description'] ??
          '',
      imageUrl: _formatImageUrl(rawImg),
      targetCategory: json['targetCategory'] ??
          json['target_category'] ??
          json['category'] ??
          json['categoryName'] ??
          json['category_name'] ??
          json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          'FRESH_VEGETABLES',
      linkedCouponCode: json['linkedCouponCode'] ??
          json['linked_coupon_code'] ??
          json['couponCode'] ??
          json['coupon_code'] ??
          json['coupon'] ??
          json['promoCode'] ??
          json['promo_code'] ??
          json['code'] ??
          'PINGZO50',
      badgeText: json['badgeText'] ??
          json['badge_text'] ??
          json['badge'] ??
          json['tag'] ??
          json['discountText'] ??
          json['discount_text'] ??
          json['offerText'] ??
          json['offer_text'] ??
          json['discount']?.toString() ??
          'FLAT AMOUNT',
      isActive: active,
      customColor: _parseColor(
        json['backgroundColor'] ??
            json['bgColor'] ??
            json['bg_color'] ??
            json['color'] ??
            json['themeColor'] ??
            json['theme_color'],
      ),
    );
  }

  static Color? _parseColor(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return Color(raw);
    String str = raw.toString().trim().replaceAll('#', '');
    if (str.isEmpty) return null;
    if (str.length == 6) str = 'FF$str';
    final parsed = int.tryParse(str, radix: 16);
    return parsed != null ? Color(parsed) : null;
  }
}


