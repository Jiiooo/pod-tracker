import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // <-- Import package cropper
import '../utils/photo_storage.dart';

class ProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String _nickname = '';
  String _bio = '';
  String? _avatarUrl;

  bool _isLoading = true;
  bool _isUploading = false;

  /// True when the server answered (profile known), false when offline with
  /// no cached profile. Only a known-empty profile should force the
  /// mandatory profile screen.
  bool _profileKnown = false;
  bool get profileKnown => _profileKnown;

  // Last profile from the server, cached per user in the `settings` box so
  // the app opens normally offline.
  Box get _settings => Hive.box('settings');
  String _cacheKey(String uid) => 'profile_$uid';

  void _writeCache() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _settings.put(_cacheKey(uid),
        {'nickname': _nickname, 'bio': _bio, 'avatar_url': _avatarUrl});
  }

  bool _readCache(String uid) {
    final c = _settings.get(_cacheKey(uid));
    if (c is! Map) return false;
    _nickname = (c['nickname'] as String?) ?? '';
    _bio = (c['bio'] as String?) ?? '';
    _avatarUrl = c['avatar_url'] as String?;
    return true;
  }

  String get nickname => _nickname;
  String get bio => _bio;
  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  ProfileProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Show the cached profile immediately, then refresh from the server.
      _profileKnown = _readCache(userId);
      final data = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();

      _nickname = data?['nickname'] ?? '';
      _bio = data?['bio'] ?? '';
      _avatarUrl = data?['avatar_url'];
      _profileKnown = true;
      _writeCache();
    } catch (e) {
      debugPrint('Gagal memuat profil (pakai cache bila ada): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI UPLOAD YANG SUDAH DILENGKAPI FITUR CROP ---
  Future<String?> uploadAvatar() async {
    final picker = ImagePicker();
    // 1. Pilih foto dari galeri
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);

    if (pickedFile == null) return null; // Batal pilih foto

    // 2. Tampilkan layar potong (Crop & Move)
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      // Kunci rasio 1:1 agar potongannya selalu berbentuk kotak/lingkaran sempurna
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Sesuaikan Foto',
          toolbarColor: const Color(0xFF1E1E1E), // Warna gelap elegan
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false, // Tampilkan tombol putar/rotate
        ),
        IOSUiSettings(
          title: 'Sesuaikan Foto',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return null; // Jika user menekan tombol 'Batal' saat mau potong

    // 3. Mulai proses upload
    _isUploading = true;
    notifyListeners();
    try {
      final file = File(croppedFile.path); // <-- Gunakan hasil foto yang SUDAH dipotong
      final fileExt = croppedFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final userId = _supabase.auth.currentUser!.id;
      final filePath = '$userId/$fileName';

      final oldPath = storagePathFromValue(_avatarUrl);

      // Upload foto baru
      await _supabase.storage.from('pod_images').upload(filePath, file);

      await _supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': filePath,
      });

      _avatarUrl = filePath;
      _writeCache();

      // Hapus foto lama setelah yang baru tersimpan; gagal hanya dicatat.
      if (oldPath != null && oldPath != filePath) {
        try {
          await _supabase.storage.from('pod_images').remove([oldPath]);
        } catch (e) {
          debugPrint('Gagal hapus avatar lama ($oldPath): $e');
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<String?> saveProfile(String newNickname, String newBio) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nickname': newNickname,
        'bio': newBio,
      });
      _nickname = newNickname;
      _bio = newBio;
      _profileKnown = true;
      _writeCache();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// 4. Fungsi Keluar Akun (Logout)
  Future<void> logout() async {
    await _supabase.auth.signOut();

    // --- TAMBAHKAN KODE INI UNTUK "CUCI OTAK" ---
    _nickname = '';
    _bio = '';
    _avatarUrl = null;
    _profileKnown = false;
    notifyListeners(); // Beritahu layar untuk mereset tampilannya
  }
}