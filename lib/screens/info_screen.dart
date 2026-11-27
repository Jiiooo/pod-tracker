import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart'; // Import Provider Cloud

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Consumer<CatalogProvider>(
        builder: (context, provider, child) {
          // Tampilkan loading saat menarik data dari internet
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jika Supabase kosong/error
          if (provider.catalogs.isEmpty) {
            return const Center(child: Text('Gagal memuat katalog panduan.'));
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
            children: [
              Text(
                'Katalog Settingan Liquid & Device',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),

              // MAPPING DATA DARI PROVIDER (SUPABASE)
              ...provider.catalogs.map((category) => _buildCategoryCard(context, category, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, LiquidCategory category, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: category.themeColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
        boxShadow: [isDark ? BoxShadow(color: category.themeColor.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 1) : BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) { if (expanded) HapticFeedback.lightImpact(); },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: category.themeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: Icon(category.icon, color: category.themeColor, size: 28)),
          title: Row(
            children: [
              Text(category.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: category.themeColor)),
              const SizedBox(width: 6),
              Expanded(child: Text(category.nicotine, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: category.themeColor.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(category.subtitle, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.3))),
          children: category.setups.map((setup) => _buildDeviceSetupTile(context, setup, isDark, category.themeColor)).toList(),
        ),
      ),
    );
  }

  Widget _buildDeviceSetupTile(BuildContext context, DeviceSetup setup, bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) { if (expanded) HapticFeedback.selectionClick(); },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(setup.deviceName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: setup.specs.map((spec) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 6.0, right: 10.0), child: CircleAvatar(radius: 3.5, backgroundColor: accentColor)), Expanded(child: Text(spec, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.5)))]),
          )).toList(),
        ),
      ),
    );
  }
}