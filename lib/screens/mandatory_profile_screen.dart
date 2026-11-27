import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pod_tracker/utils/photo_storage.dart';

import '../../providers/profile_provider.dart';
// Jika file ini di folder screens, sesuaikan import home_screen-nya
// import '../home_screen.dart';

class MandatoryProfileScreen extends StatefulWidget {
  const MandatoryProfileScreen({super.key});

  @override
  State<MandatoryProfileScreen> createState() => _MandatoryProfileScreenState();
}

class _MandatoryProfileScreenState extends State<MandatoryProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showPopup(String title, String message, IconData icon, Color iconColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade800, width: 1)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1), foregroundColor: const Color(0xFF00E5FF), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Mengerti', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    // Mencegah user kabur pakai tombol back
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(center: Alignment.center, radius: 0.8, colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)]),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SELAMAT DATANG!', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0)),
                    const SizedBox(height: 8),
                    Text('Mari lengkapi profilmu sebelum memulai.', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, height: 1.5, fontSize: 13)),
                    const SizedBox(height: 40),

                    // FOTO PROFIL (OPSIONAL)
                    GestureDetector(
                      onTap: profileProvider.isUploading ? null : () async {
                        HapticFeedback.lightImpact();
                        final error = await profileProvider.uploadAvatar();
                        if (error != null && mounted) _showPopup('Gagal Upload', error, Icons.error_outline_rounded, Colors.redAccent);
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 3), boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)]),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey.shade900,
                              child: profileProvider.avatarUrl == null ? Icon(Icons.person, size: 55, color: Colors.grey.shade700) : ClipOval(child: StoragePhoto(value: profileProvider.avatarUrl!, fit: BoxFit.cover, width: 110, height: 110)),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)]), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0a0a0a), width: 3)),
                              child: profileProvider.isUploading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Foto Profil (Opsional)', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),

                    // FORM INPUT NAMA & BIO
                    _buildPremiumInput(controller: _nicknameController, label: 'Nama Panggilan (Wajib)', icon: Icons.badge_rounded),
                    const SizedBox(height: 16),
                    _buildPremiumInput(controller: _bioController, label: 'Deskripsi Singkat (Wajib)', icon: Icons.description_rounded, maxLines: 3),
                    const SizedBox(height: 48),

                    // TOMBOL SIMPAN
                    profileProvider.isLoading && !profileProvider.isUploading
                        ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                        : _buildGradientButton(
                      text: 'SIMPAN & MULAI',
                      onPressed: () async {
                        if (_nicknameController.text.trim().isEmpty || _bioController.text.trim().isEmpty) {
                          _showPopup('Form Tidak Lengkap', 'Nama panggilan dan deskripsi wajib diisi ya.', Icons.warning_amber_rounded, Colors.orange);
                          return;
                        }

                        final error = await profileProvider.saveProfile(_nicknameController.text.trim(), _bioController.text.trim());

                        if (error != null && mounted) {
                          _showPopup('Gagal Menyimpan', error, Icons.error_outline_rounded, Colors.redAccent);
                        }
                        // JIKA SUKSES, KITA TIDAK PERLU NAVIGATOR.PUSH!
                        // AuthWrapper di main.dart akan otomatis mendeteksi perubahan nama dan memindahkan layar ke HomeScreen!
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

  Widget _buildPremiumInput({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1a1a1a), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade800, width: 1)),
      child: TextField(
        controller: controller, maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label, labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 18), child: Icon(icon, color: Colors.grey.shade500, size: 22))]),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: onPressed,
        child: Text(text, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
      ),
    );
  }
}