import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/pod_provider.dart';
import '../providers/profile_provider.dart';
import 'login_screen.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/profile_sections.dart';

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
              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
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
              ProfileAvatar(
                avatarUrl: provider.avatarUrl,
                isEditing: _isEditing,
                isUploading: provider.isUploading,
                onUpload: () => _handleUpload(provider),
              ),
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child)),
                child: _isEditing
                    ? ProfileEditMode(
                        nicknameController: _nicknameController,
                        bioController: _bioController,
                        isLoading: provider.isLoading,
                        onCancel: () => setState(() => _isEditing = false),
                        onSave: () => _handleSave(provider),
                      )
                    : ProfileViewMode(
                        nickname: provider.nickname,
                        bio: provider.bio,
                        onEdit: () {
                          _nicknameController.text = provider.nickname;
                          _bioController.text = provider.bio;
                          setState(() => _isEditing = true);
                        },
                      ),
              ),
              const SizedBox(height: 32),

              if (!_isEditing) ...[
                Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                  child: Text('Manajemen Data', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ),

                SettingsTile(
                  title: 'Backup & Export Data', subtitle: 'Simpan semua catatan ke dalam file CSV', icon: Icons.download_rounded, iconColor: Colors.blueAccent, isDark: isDark,
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
                LogoutButton(onConfirmed: () => _handleLogout(context)),
              ]
            ],
          ),
        );
      },
    );
  }

}
