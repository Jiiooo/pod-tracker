import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart'; // 👇 Import Profil Provider
import '../main.dart'; // 👇 Import main.dart untuk memanggil AuthWrapper
import 'login_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showPopup(String title, String message, IconData icon, Color iconColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
          ],
        ),
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.grey.shade400)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
              foregroundColor: const Color(0xFF00E5FF),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Mengerti', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        await authProvider.cancelRegistration();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              await authProvider.cancelRegistration();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center, radius: 0.8,
                  colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 30, spreadRadius: 8)
                        ],
                      ),
                      child: Image.asset('assets/logo_foreground.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'LANGKAH TERAKHIR',
                      style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Karena kamu mendaftar dengan Google, silakan buat password agar kedepannya kamu bisa login menggunakan Email & Password ini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, height: 1.5, fontSize: 13),
                    ),
                    const SizedBox(height: 48),

                    _buildPremiumInput(
                      controller: _passwordController,
                      label: 'Password Baru (Min. 6 Karakter)',
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),

                    _buildPremiumInput(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password',
                      icon: Icons.lock_reset_rounded,
                    ),
                    const SizedBox(height: 48),

                    authProvider.isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                        : _buildGradientButton(
                      text: 'SIMPAN & MASUK',
                      onPressed: () async {
                        if (_passwordController.text.length < 6) {
                          _showPopup('Password Lemah', 'Password minimal harus terdiri dari 6 karakter.', Icons.shield_outlined, Colors.orange);
                          return;
                        }
                        if (_passwordController.text != _confirmPasswordController.text) {
                          _showPopup('Validasi Gagal', 'Kolom konfirmasi password tidak sesuai dengan password yang kamu masukkan.', Icons.warning_amber_rounded, Colors.redAccent);
                          return;
                        }

                        final error = await authProvider.setPassword(_passwordController.text.trim());

                        if (error == null && context.mounted) {
                          // 👇 REFRESH PROFIL & ARAHKAN KE SATPAM (AuthWrapper) 👇
                          await Provider.of<ProfileProvider>(context, listen: false).loadProfile();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthWrapper()),
                                  (Route<dynamic> route) => false,
                            );
                          }
                        } else if (error != null && context.mounted) {
                          _showPopup('Gagal Menyimpan', error, Icons.error_outline_rounded, Colors.redAccent);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInput({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscureText,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 20),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(text, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
      ),
    );
  }
}