import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pod_config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PodProvider with ChangeNotifier {
  final Box<PodConfig> _box = Hive.box<PodConfig>('podBox');
  final _supabase = Supabase.instance.client;

  List<PodConfig> _configs = [];
  List<PodConfig> get configs => _configs;

  // --- VARIABEL LOADING YANG HILANG ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String _sortBy = 'date';

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  PodProvider() {
    syncData(); // Panggil fungsi publik
  }

  void clearData() {
    _configs = [];
    _box.clear();
    notifyListeners();
  }

  // --- 1. SINKRONISASI OTOMATIS DENGAN ANIMASI LOADING ---
  Future<void> syncData() async {
    // NYALAKAN LOADING
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        clearData();
        return;
      }

      final List<dynamic> data = await _supabase.from('pod_configs').select().eq('user_id', userId);
      await _box.clear();

      for (var item in data) {
        final config = PodConfig(
          id: item['id'],
          userId: item['user_id'],
          deviceName: item['device_name'] ?? 'Lainnya',
          resistance: (item['resistance'] as num).toDouble(),
          liquidName: item['liquid_name'],
          optimalWattage: item['optimal_wattage'] as int,
          airflowLevel: item['airflow_level'],
          flavorRating: (item['flavor_rating'] as num).toDouble(),
          dateStarted: DateTime.parse(item['date_started']),
          isStillActive: item['is_still_active'] ?? true,
          price: (item['price'] as num).toDouble(),
          imagePath: item['image_path'],
          flavorTags: List<String>.from(item['flavor_tags'] ?? []),
        );
        await _box.put(config.id, config);
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _loadLocalData();

      // MATIKAN LOADING
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadLocalData() {
    _configs = _currentUserId != null
        ? _box.values.where((c) => c.userId == _currentUserId).toList()
        : [];
    notifyListeners();
  }

  // --- 2. MANAJEMEN DATA & CLOUD STORAGE ---
  Future<String?> _uploadLiquidImage(String? localImagePath) async {
    if (localImagePath == null || localImagePath.startsWith('http')) return localImagePath;

    try {
      final file = File(localImagePath);
      final fileName = 'liquid_${DateTime.now().millisecondsSinceEpoch}.${localImagePath.split('.').last}';
      final filePath = '$_currentUserId/$fileName';

      await _supabase.storage.from('pod_images').upload(filePath, file);
      return _supabase.storage.from('pod_images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Upload Foto Error: $e');
      return localImagePath;
    }
  }

  Future<void> addConfig(PodConfig config) async {
    try {
      final cloudImagePath = await _uploadLiquidImage(config.imagePath);
      final newConfig = PodConfig(
        id: config.id, userId: config.userId, deviceName: config.deviceName,
        resistance: config.resistance, liquidName: config.liquidName,
        optimalWattage: config.optimalWattage, airflowLevel: config.airflowLevel,
        flavorRating: config.flavorRating, dateStarted: config.dateStarted,
        isStillActive: config.isStillActive, price: config.price,
        imagePath: cloudImagePath, flavorTags: config.flavorTags,
      );

      await _supabase.from('pod_configs').insert({
        'id': newConfig.id, 'user_id': newConfig.userId, 'device_name': newConfig.deviceName,
        'resistance': newConfig.resistance, 'liquid_name': newConfig.liquidName,
        'optimal_wattage': newConfig.optimalWattage, 'airflow_level': newConfig.airflowLevel,
        'flavor_rating': newConfig.flavorRating, 'date_started': newConfig.dateStarted.toIso8601String(),
        'is_still_active': newConfig.isStillActive, 'price': newConfig.price,
        'image_path': newConfig.imagePath, 'flavor_tags': newConfig.flavorTags,
      });

      await _box.put(newConfig.id, newConfig);
      _loadLocalData();
    } catch (e) {
      debugPrint('Add Error: $e');
      rethrow;
    }
  }

  Future<void> updateConfig(PodConfig newConfig) async {
    try {
      final cloudImagePath = await _uploadLiquidImage(newConfig.imagePath);

      await _supabase.from('pod_configs').update({
        'device_name': newConfig.deviceName, 'resistance': newConfig.resistance,
        'liquid_name': newConfig.liquidName, 'optimal_wattage': newConfig.optimalWattage,
        'airflow_level': newConfig.airflowLevel, 'flavor_rating': newConfig.flavorRating,
        'date_started': newConfig.dateStarted.toIso8601String(), 'is_still_active': newConfig.isStillActive,
        'price': newConfig.price, 'image_path': cloudImagePath, 'flavor_tags': newConfig.flavorTags,
      }).eq('id', newConfig.id).eq('user_id', _currentUserId!);

      final updatedConfig = PodConfig(
        id: newConfig.id, userId: newConfig.userId, deviceName: newConfig.deviceName,
        resistance: newConfig.resistance, liquidName: newConfig.liquidName,
        optimalWattage: newConfig.optimalWattage, airflowLevel: newConfig.airflowLevel,
        flavorRating: newConfig.flavorRating, dateStarted: newConfig.dateStarted,
        isStillActive: newConfig.isStillActive, price: newConfig.price,
        imagePath: cloudImagePath, flavorTags: newConfig.flavorTags,
      );

      await _box.put(updatedConfig.id, updatedConfig);
      _loadLocalData();
    } catch(e) {
      debugPrint('Update Error: $e');
      rethrow;
    }
  }

  Future<void> deleteConfig(String id) async {
    try {
      await _supabase.from('pod_configs').delete().eq('id', id);
      await _box.delete(id);
      _loadLocalData();
    } catch (e) {
      debugPrint('Delete Error: $e');
      rethrow;
    }
  }

  // --- 3. FILTER, SORTING & STATISTIK UI ---
  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }
  void setSortBy(String sort) { _sortBy = sort; notifyListeners(); }

  List<PodConfig> get activeConfigs {
    var filtered = _configs.where((c) => c.isStillActive).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
      c.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.liquidName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    if (_sortBy == 'date') filtered.sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
    else if (_sortBy == 'rating') filtered.sort((a, b) => b.flavorRating.compareTo(a.flavorRating));

    return filtered;
  }

  List<PodConfig> get archivedConfigs => _configs.where((c) => !c.isStillActive).toList();
  double get totalExpense => _configs.fold(0.0, (sum, item) => sum + item.price);

  // --- 4. ARSIP & EXPORT CSV ---
  Future<void> archiveConfig(String id) async {
    final existing = _box.get(id);
    if (existing != null) { existing.isStillActive = false; await updateConfig(existing); }
  }

  Future<void> restoreConfig(String id) async {
    final existing = _box.get(id);
    if (existing != null) { existing.isStillActive = true; await updateConfig(existing); }
  }

  Future<void> exportToCSV() async {
    try {
      String csvData = "Device,Liquid,Resistance(Ohm),Watt,Rating,Harga,Tanggal\n";
      for (var c in _configs) {
        csvData += "${c.deviceName},${c.liquidName},${c.resistance},${c.optimalWattage},${c.flavorRating},${c.price},${c.dateStarted.toIso8601String().split('T')[0]}\n";
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Backup_Tracker_Pod.csv';
      await File(path).writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Backup Data Pod Tracker');
    } catch (e) {
      debugPrint('CSV Error: $e');
      rethrow;
    }
  }
}