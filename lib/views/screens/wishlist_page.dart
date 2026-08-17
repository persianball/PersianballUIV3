// lib/views/screens/wishlist_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/catalog_service.dart';
import 'package:marketky/services/wishlist_service.dart';
import 'package:marketky/views/screens/catalog_page.dart';
import 'package:marketky/views/widgets/item_card.dart';

/// لیست علاقه‌مندی‌ها و بازدیدهای اخیر
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _loading = true;
  String? _error;
  List<Product> _favorites = [];
  List<Product> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await CatalogService.fetchAllProducts();
      final favIds = await WishlistService.favorites();
      final recentIds = await WishlistService.recentlyViewed();
      final byId = {for (final p in all) p.id: p};
      setState(() {
        _favorites = favIds.map((id) => byId[id]).whereType<Product>().toList();
        _recent = recentIds
            .where((id) => !favIds.contains(id))
            .map((id) => byId[id])
            .whereType<Product>()
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'دریافت اطلاعات ناموفق بود';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('علاقه‌مندی‌ها',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.goldEnd, shape: const RoundedRectangleBorder()),
              child: const Text('تلاش مجدد',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.goldEnd,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (_favorites.isEmpty) _emptyFavorites() else _grid(_favorites),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('بازدیدهای اخیر',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
            const SizedBox(height: 12),
            _grid(_recent),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _grid(List<Product> products) => Wrap(
        spacing: 16,
        runSpacing: 16,
        children: products.map((p) => ItemCard(product: p, dark: true)).toList(),
      );

  Widget _emptyFavorites() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 48, color: AppColor.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('هنوز کالایی به علاقه‌مندی‌ها اضافه نکرده‌اید',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
            child: const Text('مشاهده محصولات',
                style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
          ),
        ],
      ),
    );
  }
}
