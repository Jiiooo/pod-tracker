import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pod_config.dart';
import '../utils/photo_storage.dart';
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

  String? _syncError;
  String? get syncError => _syncError;

  int get pendingCount {
    final uid = _currentUserId;
    if (uid == null) return 0;
    return _box.values.where((c) => c.userId == uid && c.syncStatus == 'pending').length;
  }

  bool _pushing = false;
  bool _syncing = false;

  /// Logout: hanya kosongkan memori, data lokal (Hive) tetap aman.
  void clearData() {
    _configs = [];
    notifyListeners();
  }

  // --- 1. SINKRONISASI OFFLINE-FIRST ---
  Future<void> syncData() async {
    if (_syncing) return;
    _syncing = true;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        _configs = [];
        return;
      }

      _loadLocalData();
      await pushPending();

      final List<dynamic> data =
          await _supabase.from('pod_configs').select().eq('user_id', userId);

      final remoteIds = <String>{};
      for (final item in data) {
        try {
          final remote = podConfigFromRow(Map<String, dynamic>.from(item as Map));
          if (remote.id.isEmpty) continue;
          remoteIds.add(remote.id);
          final local = _box.get(remote.id);
          if (local != null && local.syncStatus == 'pending') continue;
          await _box.put(remote.id, remote);
        } catch (e) {
          debugPrint('Sync: baris rusak dilewati: $e');
        }
      }

      final stale = _box.values
          .where((c) => c.userId == userId && c.syncStatus == 'synced' && !remoteIds.contains(c.id))
          .map((c) => c.id)
          .toList();
      for (final id in stale) {
        await _box.delete(id);
      }

      if (pendingCount == 0) _syncError = null;
    } catch (e) {
      debugPrint('Sync Error: $e');
      _syncError = 'Gagal sinkronisasi. Data tersimpan di perangkat.';
    } finally {
      _loadLocalData();
      _syncing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadLocalData() {
    final uid = _currentUserId;
    _configs = uid != null
        ? _box.values.where((c) => c.userId == uid && !c.isDeleted).toList()
        : [];
    notifyListeners();
  }

  // --- 2. ANTREAN PUSH ---
  Future<String?> _uploadLiquidImage(String localImagePath) async {
    final file = File(localImagePath);
    final ext = localImagePath.contains('.') ? localImagePath.split('.').last : 'jpg';
    final fileName = 'liquid_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '$_currentUserId/$fileName';
    await _supabase.storage.from('pod_images').upload(filePath, file);
    return filePath;
  }

  /// Hapus objek foto lama. Gagal hanya dicatat, tidak boleh memblokir sync.
  Future<void> _removeStoredPhoto(String? value) async {
    final path = storagePathFromValue(value);
    if (path == null) return;
    try {
      await _supabase.storage.from('pod_images').remove([path]);
    } catch (e) {
      debugPrint('Gagal hapus foto lama ($path): $e');
    }
  }

  Future<String?> _remoteImageValue(String id, String uid) async {
    try {
      final row = await _supabase
          .from('pod_configs')
          .select('image_path')
          .eq('id', id)
          .eq('user_id', uid)
          .maybeSingle();
      return row?['image_path'] as String?;
    } catch (e) {
      debugPrint('Gagal baca foto lama ($id): $e');
      return null;
    }
  }

  Future<void> pushPending() async {
    if (_pushing) return;
    final uid = _currentUserId;
    if (uid == null) return;
    _pushing = true;
    try {
      final pending = _box.values
          .where((c) => c.userId == uid && c.syncStatus == 'pending')
          .toList();
      var failed = false;

      for (final live in pending) {
        final snap = _copyPending(live, deleted: live.isDeleted);
        final c = snap;
        try {
          if (c.isDeleted) {
            final oldImage = await _remoteImageValue(c.id, uid);
            await _supabase.from('pod_configs').delete().eq('id', c.id).eq('user_id', uid);
            await _box.delete(c.id);
            await _removeStoredPhoto(oldImage ?? (isLocalFile(c.imagePath) ? null : c.imagePath));
            continue;
          }

          var imagePath = c.imagePath;
          String? oldImage;
          if (isLocalFile(imagePath)) {
            oldImage = await _remoteImageValue(c.id, uid);
            imagePath = await _uploadLiquidImage(imagePath!);
          }

          final toPush = _copyPending(snap)..imagePath = imagePath;
          await _supabase.from('pod_configs').upsert(podConfigToRow(toPush));
          if (oldImage != null && oldImage != imagePath) {
            await _removeStoredPhoto(oldImage);
          }

          // Hanya tandai synced jika record tidak diubah lagi selama proses upload.
          final current = _box.get(c.id);
          if (current != null && !current.isDeleted && current.syncStatus == 'pending' &&
              _sameContent(current, snap)) {
            toPush.syncStatus = 'synced';
            await _box.put(c.id, toPush);
          } else if (current != null && imagePath != current.imagePath &&
              current.imagePath == snap.imagePath) {
            current.imagePath = imagePath;
            await _box.put(c.id, current);
          }
        } catch (e) {
          failed = true;
          debugPrint('Push Error (${c.id}): $e');
        }
      }

      if (failed) {
        _syncError = 'Sebagian data belum terkirim ke cloud. Coba lagi nanti.';
      } else {
        _syncError = null;
      }
    } finally {
      _pushing = false;
      _loadLocalData();
    }
  }

  bool _sameContent(PodConfig a, PodConfig b) =>
      a.deviceName == b.deviceName && a.resistance == b.resistance &&
      a.liquidName == b.liquidName && a.optimalWattage == b.optimalWattage &&
      a.airflowLevel == b.airflowLevel && a.flavorRating == b.flavorRating &&
      a.dateStarted == b.dateStarted && a.isStillActive == b.isStillActive &&
      a.price == b.price && a.imagePath == b.imagePath &&
      a.flavorTags.join('\u0000') == b.flavorTags.join('\u0000');

  PodConfig _copyPending(PodConfig c, {bool deleted = false}) => PodConfig(
        id: c.id, userId: c.userId, deviceName: c.deviceName,
        resistance: c.resistance, liquidName: c.liquidName,
        optimalWattage: c.optimalWattage, airflowLevel: c.airflowLevel,
        flavorRating: c.flavorRating, dateStarted: c.dateStarted,
        isStillActive: c.isStillActive, price: c.price,
        imagePath: c.imagePath, flavorTags: List<String>.from(c.flavorTags),
        syncStatus: 'pending', isDeleted: deleted,
      );

  Future<void> _push() async {
    try {
      await pushPending();
    } catch (e) {
      debugPrint('Push Error: $e');
    }
    notifyListeners();
  }

  Future<void> addConfig(PodConfig config) async {
    await _box.put(config.id, _copyPending(config));
    _loadLocalData();
    await _push();
  }

  Future<void> updateConfig(PodConfig newConfig) async {
    await _box.put(newConfig.id, _copyPending(newConfig));
    _loadLocalData();
    await _push();
  }

  Future<void> deleteConfig(String id) async {
    final existing = _box.get(id);
    if (existing == null) return;
    await _box.put(id, _copyPending(existing, deleted: true));
    _loadLocalData();
    await _push();
  }

  // --- 3. FILTER, SORTING & STATISTIK UI ---
  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }
  void setSortBy(String sort) { _sortBy = sort; notifyListeners(); }

  List<PodConfig> get activeConfigs {
    var filtered = _configs.where((c) => c.isStillActive && !c.isDeleted).toList();
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

  List<PodConfig> get archivedConfigs => _configs.where((c) => !c.isStillActive && !c.isDeleted).toList();
  double get totalExpense => _configs.where((c) => !c.isDeleted).fold(0.0, (sum, item) => sum + item.price);

  // --- 4. ARSIP & EXPORT CSV ---
  Future<void> archiveConfig(String id) async {
    final existing = _box.get(id);
    if (existing != null && !existing.isDeleted) {
      final copy = _copyPending(existing)..isStillActive = false;
      await updateConfig(copy);
    }
  }

  Future<void> restoreConfig(String id) async {
    final existing = _box.get(id);
    if (existing != null && !existing.isDeleted) {
      final copy = _copyPending(existing)..isStillActive = true;
      await updateConfig(copy);
    }
  }

  Future<void> exportToCSV() async {
    try {
      String csvData = "Device,Liquid,Resistance(Ohm),Watt,Rating,Harga,Tanggal\n";
      for (var c in _configs.where((c) => !c.isDeleted)) {
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