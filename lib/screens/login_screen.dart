import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart'; // 👇 Import Profil Provider
import '../main.dart'; // 👇 Import main.dart untuk memanggil AuthWrapper
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.grey.shade400),
        ),
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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
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
                    'POD TRACKER',
                    style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk ke akunmu untuk sinkronisasi Real-time',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 48),

                  _buildPremiumInput(
                    controller: _emailController,
                    label: 'Alamat Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInput(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                      : _buildGradientButton(
                    text: 'MASUK SEKARANG',
                    onPressed: () async {
                      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                        _showPopup('Form Tidak Lengkap', 'Email dan Password wajib diisi untuk melanjutkan.', Icons.warning_amber_rounded, Colors.orange);
                        return;
                      }
                      final error = await authProvider.loginWithEmail(_emailController.text.trim(), _passwordController.text.trim());

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
                        String errorMessage = error;
                        if (error.toLowerCase().contains('invalid login credentials')) {
                          errorMessage = 'Email atau password yang kamu masukkan salah. Silakan periksa kembali.';
                        }
                        _showPopup('Login Gagal', errorMessage, Icons.error_outline_rounded, Colors.redAccent);
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade800)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('ATAU', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12))
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade800)),
                      ]
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 24, height: 24),
                      label: Text('Lanjutkan dengan Google', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: authProvider.isLoading ? null : () async {
                        final error = await authProvider.authenticateWithGoogle(isLogin: true);

                        if (error == 'SILENT_CANCEL') return;

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
                          _showPopup('Gagal Masuk', error, Icons.error_outline_rounded, Colors.redAccent);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: RichText(
                      text: TextSpan(
                        text: 'Belum punya akun? ',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Daftar di sini',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
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

  Widget _buildPremiumInput({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 20),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          )
              : null,
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