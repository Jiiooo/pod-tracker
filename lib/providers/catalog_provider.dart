import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Struktur Data Lokal untuk membaca JSON dari Supabase
class DeviceSetup {
  final String deviceName;
  final List<String> specs;
  DeviceSetup({required this.deviceName, required this.specs});
}

class LiquidCategory {
  final String title;
  final String nicotine;
  final String subtitle;
  final Color themeColor;
  final IconData icon;
  final List<DeviceSetup> setups;

  LiquidCategory({
    required this.title, required this.nicotine, required this.subtitle,
    required this.themeColor, required this.icon, required this.setups,
  });
}

class CatalogProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<LiquidCategory> _catalogs = [];
  bool _isLoading = true;

  List<LiquidCategory> get catalogs => _catalogs;
  bool get isLoading => _isLoading;

  CatalogProvider() {
    fetchCatalogs();
  }

  // Fungsi helper untuk menerjemahkan nama icon dari Supabase menjadi IconData Flutter
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'water_drop_outlined': return Icons.water_drop_outlined;
      case 'water_drop_rounded': return Icons.water_drop_rounded;
      case 'opacity_rounded': return Icons.opacity_rounded;
      default: return Icons.info_outline;
    }
  }

  Future<void> fetchCatalogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Menarik data dari Supabase, diurutkan berdasarkan sort_order
      final response = await _supabase.from('vape_catalogs').select().order('sort_order', ascending: true);

      _catalogs = response.map<LiquidCategory>((data) {
        // Ekstrak list JSON setup menjadi list objek Dart
        var setupsJson = data['setups'] as List<dynamic>;
        List<DeviceSetup> parsedSetups = setupsJson.map((s) => DeviceSetup(
          deviceName: s['deviceName'],
          specs: List<String>.from(s['specs']),
        )).toList();

        return LiquidCategory(
          title: data['title'],
          nicotine: data['nicotine'],
          subtitle: data['subtitle'],
          themeColor: Color(int.parse(data['theme_color'])), // Ubah Hex String (0xFF...) jadi Color
          icon: _getIconFromName(data['icon_name']),
          setups: parsedSetups,
        );
      }).toList();

    } catch (e) {
      debugPrint('Gagal fetch katalog dari Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}