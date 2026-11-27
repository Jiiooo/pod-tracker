import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pod_config.dart';
import '../utils/csv_codec.dart';
import '../utils/photo_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
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
  Set<String> _selectedTags = {};

  // Cache daftar hasil filter/sort; dihitung ulang hanya saat _dirty.
  bool _dirty = true;
  List<PodConfig> _activeCache = const [];
  List<PodConfig> _archivedCache = const [];
  List<String> _tagsCache = const [];

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
    _selectedTags = {};
    _dirty = true;
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
    _dirty = true;
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
  Future<void> _removeStoredPhoto(String? value, {String? exceptId}) async {
    final path = storagePathFromValue(value);
    if (path == null) return;
    // "Pakai lagi" membagi satu foto ke beberapa entri: jangan hapus bila masih dipakai.
    final stillUsed = _box.values.any((c) =>
        c.id != exceptId && !c.isDeleted && storagePathFromValue(c.imagePath) == path);
    if (stillUsed) return;
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
            await _removeStoredPhoto(oldImage ?? (isLocalFile(c.imagePath) ? null : c.imagePath), exceptId: c.id);
            continue;
          }

          var imagePath = c.imagePath;
          String? oldImage;
          String? uploaded; // objek yang baru diupload di putaran ini
          if (isLocalFile(imagePath)) {
            oldImage = await _remoteImageValue(c.id, uid);
            imagePath = await _uploadLiquidImage(imagePath!);
            uploaded = imagePath;
          }

          final toPush = _copyPending(snap)..imagePath = imagePath;
          try {
            await _supabase.from('pod_configs').upsert(podConfigToRow(toPush));
          } catch (_) {
            // Upload berhasil tapi upsert gagal: hapus objek yatim agar retry
            // tidak menumpuk file. Record tetap pending dengan path lokal.
            if (uploaded != null) await _removeStoredPhoto(uploaded, exceptId: c.id);
            rethrow;
          }
          if (oldImage != null && oldImage != imagePath) {
            await _removeStoredPhoto(oldImage, exceptId: c.id);
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

  /// Tambah banyak record sekaligus dengan satu kali push.
  Future<void> addConfigs(List<PodConfig> configs) async {
    for (final c in configs) {
      await _box.put(c.id, _copyPending(c));
    }
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
  void setSearchQuery(String query) { _searchQuery = query; _dirty = true; notifyListeners(); }
  void setSortBy(String sort) { _sortBy = sort; _dirty = true; notifyListeners(); }

  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);

  void toggleTag(String tag) {
    final existing = _selectedTags.where((t) => t.toLowerCase() == tag.toLowerCase()).toList();
    if (existing.isEmpty) {
      _selectedTags = {..._selectedTags, tag};
    } else {
      _selectedTags = _selectedTags.difference(existing.toSet());
    }
    _dirty = true;
    notifyListeners();
  }

  void clearTagFilter() {
    if (_selectedTags.isEmpty) return;
    _selectedTags = {};
    _dirty = true;
    notifyListeners();
  }

  /// Semua tag dari config yang tidak dihapus, unik (tanpa beda huruf), terurut.
  List<String> get availableTags {
    _refresh();
    return _tagsCache;
  }

  List<PodConfig> get activeConfigs {
    _refresh();
    return _activeCache;
  }

  List<PodConfig> get archivedConfigs {
    _refresh();
    return _archivedCache;
  }

  void _refresh() {
    if (!_dirty) return;
    _dirty = false;

    final live = _configs.where((c) => !c.isDeleted).toList();

    final seen = <String, String>{};
    for (final c in live) {
      for (final t in c.flavorTags) {
        final trimmed = t.trim();
        if (trimmed.isNotEmpty) seen.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
      }
    }
    _tagsCache = seen.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Buang tag terpilih yang sudah tidak ada lagi.
    _selectedTags = _selectedTags.where((t) => seen.containsKey(t.toLowerCase())).toSet();
    final wanted = _selectedTags.map((t) => t.toLowerCase()).toSet();
    bool tagOk(PodConfig c) =>
        wanted.isEmpty || c.flavorTags.any((t) => wanted.contains(t.trim().toLowerCase()));

    final q = _searchQuery.toLowerCase();
    final active = live.where((c) {
      if (!c.isStillActive || !tagOk(c)) return false;
      return q.isEmpty ||
          c.deviceName.toLowerCase().contains(q) ||
          c.liquidName.toLowerCase().contains(q);
    }).toList();
    if (_sortBy == 'date') {
      active.sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
    } else if (_sortBy == 'rating') {
      active.sort((a, b) => b.flavorRating.compareTo(a.flavorRating));
    }
    _activeCache = active;
    _archivedCache = live.where((c) => !c.isStillActive && tagOk(c)).toList();
  }

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

  /// Ringkasan entri sebelumnya dengan nama liquid sama (tanpa beda huruf).
  /// Null jika tidak ada.
  ({int count, double lastRating})? historyFor(String liquidName, {String? excludeId}) {
    final q = liquidName.trim().toLowerCase();
    if (q.isEmpty) return null;
    final matches = _configs
        .where((c) => !c.isDeleted && c.id != excludeId && c.liquidName.trim().toLowerCase() == q)
        .toList();
    if (matches.isEmpty) return null;
    final last = matches.reduce((a, b) => a.dateStarted.isAfter(b.dateStarted) ? a : b);
    return (count: matches.length, lastRating: last.flavorRating);
  }

  Future<void> exportToCSV() async {
    try {
      final csvData = podsToCsv(_configs.where((c) => !c.isDeleted));
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Backup_Tracker_Pod.csv';
      await File(path).writeAsString(csvData);

      await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Backup Data Pod Tracker'));
    } catch (e) {
      debugPrint('CSV Error: $e');
      rethrow;
    }
  }

  /// Pilih file CSV lalu buat record BARU dari isinya. Null jika dibatalkan.
  Future<CsvImportResult?> importFromCSV() async {
    final uid = _currentUserId;
    if (uid == null) throw StateError('Sesi terputus. Silakan login ulang.');

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final f = picked.files.single;
    final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
    if (bytes == null) throw StateError('File tidak bisa dibaca.');

    final stamp = DateTime.now().toString();
    final result = parsePodCsv(
      utf8.decode(bytes, allowMalformed: true),
      userId: uid,
      newId: (i) => '$stamp#$i',
    );
    if (result.configs.isNotEmpty) await addConfigs(result.configs);
    return result;
  }
}
