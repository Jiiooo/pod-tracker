import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1. LOGIN MANUAL (EMAIL & PASSWORD)
  Future<String?> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 2. DAFTAR MANUAL (EMAIL & PASSWORD)
  Future<String?> registerWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'registration_complete': true},
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 3. LOGIKA CERDAS GOOGLE (SSO) DENGAN PEMISAHAN LOGIN & DAFTAR
  Future<String?> authenticateWithGoogle({required bool isLogin}) async {
    _setLoading(true);
    try {
      const webClientId = '663308408690-ttg8k9nclicn1mqn0obgr474jrvrhfel.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: webClientId);

      final googleUser = await googleSignIn.authenticate();

      // 👇 CEGAT PEMBATALAN: Jika batal pilih email Google
      if (googleUser == null) return 'SILENT_CANCEL';

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw 'ID Token tidak ditemukan!';

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = res.user;
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        final providers = user.appMetadata['providers'] as List<dynamic>? ?? [];

        final isRegistered = metadata['registration_complete'] == true || providers.contains('email');

        if (isLogin) {
          if (!isRegistered) {
            await _supabase.auth.signOut();
            await googleSignIn.signOut();
            return 'Data tidak ditemukan! Silakan mendaftar terlebih dahulu di halaman Daftar.';
          }
        } else {
          if (isRegistered) {
            await _supabase.auth.signOut();
            await googleSignIn.signOut();
            return 'Data user ini sudah pernah mendaftar! Silakan langsung gunakan tombol Login.';
          }
        }
      }
      return null;
    } catch (e) {
      final errorString = e.toString();
      // 👇 CEGAT PEMBATALAN TEKNIS (Tombol Back Android)
      if (errorString.contains('canceled') || errorString.contains('Cancelled by user')) {
        return 'SILENT_CANCEL';
      }
      return errorString;
    } finally {
      _setLoading(false);
    }
  }

  // 4. SIMPAN PASSWORD BARU SETELAH DAFTAR VIA GOOGLE
  Future<String?> setPassword(String password) async {
    _setLoading(true);
    try {
      await _supabase.auth.updateUser(
          UserAttributes(
            password: password,
            data: {'registration_complete': true},
          )
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 5. BATALKAN REGISTRASI (Jika user menekan tombol Back)
  Future<void> cancelRegistration() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Error membatalkan: $e');
    } finally {
      _setLoading(false);
    }
  }
}