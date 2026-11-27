import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pod_tracker/utils/photo_storage.dart';

import '../providers/pod_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _nicknameController.text = profileProvider.nickname;
      _bioController.text = profileProvider.bio;
      if (_nicknameController.text.isEmpty && !profileProvider.isLoading) {
        _isEditing = true;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 👇 FUNGSI PREMIUM POP-UP (MENGGANTIKAN SNACKBAR)
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

  Future<void> _handleSave(ProfileProvider provider) async {
    HapticFeedback.lightImpact();
    final error = await provider.saveProfile(_nicknameController.text, _bioController.text);

    if (mounted) {
      if (error == null) {
        setState(() => _isEditing = false);
        _showPopup('Berhasil', 'Profil kamu berhasil disimpan ke awan.', Icons.check_circle_outline_rounded, Colors.greenAccent);
      } else {
        _showPopup('Gagal Menyimpan', error, Icons.error_outline_rounded, Colors.redAccent);
      }
    }
  }

  Future<void> _handleUpload(ProfileProvider provider) async {
    final error = await provider.uploadAvatar();
    if (mounted && error != null) {
      _showPopup('Gagal Upload', error, Icons.error_outline_rounded, Colors.redAccent);
    } else if (mounted && error == null && provider.avatarUrl != null) {
      _showPopup('Berhasil', 'Foto profil berhasil diperbarui.', Icons.check_circle_outline_rounded, Colors.greenAccent);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.lightImpact();

    // 1. Bersihkan data Pod Lokal
    Provider.of<PodProvider>(context, listen: false).clearData();
    // 2. Bersihkan State Profil
    await Provider.of<ProfileProvider>(context, listen: false).logout();

    // 3. (Opsional tapi disarankan) Panggil AuthProvider jika kamu menaruh fungsi signout di sana
    // await Provider.of<AuthProvider>(context, listen: false).signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.avatarUrl == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }

        return Scaffold(
          backgroundColor: surfaceColor,
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 100.0),
            children: [
              _buildAvatarSection(provider, primaryColor, surfaceColor, isDark),
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child)),
                child: _isEditing ? _buildEditMode(provider, isDark, primaryColor) : _buildViewMode(provider, isDark, primaryColor),
              ),
              const SizedBox(height: 32),

              if (!_isEditing) ...[
                Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                  child: Text('Manajemen Data', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ),

                _buildSettingsTile(
                  context, title: 'Backup & Export Data', subtitle: 'Simpan semua catatan ke dalam file CSV', icon: Icons.download_rounded, iconColor: Colors.blueAccent, isDark: isDark,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    try {
                      await context.read<PodProvider>().exportToCSV();
                    } catch (e) {
                      if (context.mounted) _showPopup('Gagal Export', e.toString(), Icons.error_outline_rounded, Colors.redAccent);
                    }
                  },
                ),

                const SizedBox(height: 24),
                _buildLogoutButton(context),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(ProfileProvider provider, Color primaryColor, Color surfaceColor, bool isDark) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withOpacity(_isEditing ? 0.8 : 0.2), width: _isEditing ? 3 : 2), boxShadow: [BoxShadow(color: primaryColor.withOpacity(isDark ? 0.2 : 0.3), blurRadius: 20, spreadRadius: _isEditing ? 5 : 2, offset: const Offset(0, 8))]),
            child: GestureDetector(
              onTap: () {
                if (provider.avatarUrl != null) {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenAvatarView(imageUrl: provider.avatarUrl!)));
                }
              },
              child: Hero(
                tag: 'profile_avatar_hero',
                child: CircleAvatar(
                  radius: 65, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: provider.avatarUrl == null ? Icon(Icons.person, size: 65, color: Colors.grey.shade400) : ClipOval(child: StoragePhoto(value: provider.avatarUrl!, fit: BoxFit.cover, width: 130, height: 130)),
                ),
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0, right: 4,
              child: GestureDetector(
                onTap: provider.isUploading ? null : () => _handleUpload(provider),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: provider.isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewMode(ProfileProvider provider, bool isDark, Color primaryColor) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bioText = provider.bio.isNotEmpty ? provider.bio : 'Belum ada deskripsi profil.';

    return Column(
      key: const ValueKey('ViewMode'),
      children: [
        Text(
          provider.nickname.isNotEmpty ? provider.nickname : 'Pengguna Baru',
          style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5), textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: Text(bioText, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor.withOpacity(0.7), height: 1.5), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50, width: 200,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _nicknameController.text = provider.nickname;
              _bioController.text = provider.bio;
              setState(() => _isEditing = true);
            },
            icon: const Icon(Icons.edit_rounded, size: 18), label: Text('Edit Profil', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(ProfileProvider provider, bool isDark, Color primaryColor) {
    return Column(
      key: const ValueKey('EditMode'),
      children: [
        _buildPremiumTextField(controller: _nicknameController, label: 'Nama Panggilan', icon: Icons.badge_rounded, isDark: isDark),
        const SizedBox(height: 20),
        _buildPremiumTextField(controller: _bioController, label: 'Deskripsi Diri / Bio', icon: Icons.description_rounded, isDark: isDark, maxLines: 3),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: () { HapticFeedback.lightImpact(); setState(() => _isEditing = false); },
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)], begin: Alignment.centerLeft, end: Alignment.centerRight), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
                child: ElevatedButton(
                  onPressed: () => _handleSave(provider),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: provider.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Simpan', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color iconColor, required bool isDark, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildPremiumTextField({required TextEditingController controller, required String label, required IconData icon, required bool isDark, int maxLines = 1}) {
    final fillColor = isDark ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.grey.shade100;
    return TextFormField(
      controller: controller, maxLines: maxLines, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        prefixIcon: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 18), child: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)))]),
        filled: true, fillColor: fillColor, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 56, width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1a1a1a),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade800, width: 1)),
              title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent), const SizedBox(width: 8), Text('Konfirmasi', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold))]),
              content: Text('Apakah kamu yakin ingin keluar dari akun ini?', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.white))),
                ElevatedButton(onPressed: () { Navigator.pop(ctx); _handleLogout(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0), child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), label: Text('Keluar Akun', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

class FullScreenAvatarView extends StatelessWidget {
  final String imageUrl;
  const FullScreenAvatarView({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: Hero(tag: 'profile_avatar_hero', child: InteractiveViewer(child: StoragePhoto(value: imageUrl, fit: BoxFit.contain)))),
    );
  }
}