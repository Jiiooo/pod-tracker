import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'set_password_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  void _showPopup(BuildContext context, String title, String message, IconData icon, Color iconColor) {
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

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // Membiarkan background gradient menembus appbar
      body: Stack(
        children: [
          // Background Gradient Radial Premium
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dengan Efek Glow
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
                    'DAFTAR AKUN BARU',
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Cukup 1 klik menggunakan akun Google kamu untuk mengaktifkan sinkronisasi awan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 56),

                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                      : SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 24, height: 24),
                      label: Text('Daftar dengan Google', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () async {
                        final error = await authProvider.authenticateWithGoogle(isLogin: false);

                        // 👇 CEK SILENT CANCEL 👇
                        if (error == 'SILENT_CANCEL') {
                          return; // Keluar dari fungsi secara diam-diam (tanpa popup)
                        }

                        if (error == null && context.mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetPasswordScreen()));
                        } else if (error != null && context.mounted) {
                          _showPopup(context, 'Pendaftaran Ditolak', error, Icons.warning_amber_rounded, Colors.orange);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}