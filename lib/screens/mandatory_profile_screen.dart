import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/auth_scaffold.dart';
import 'widgets/profile_avatar.dart';

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

  void _popup(String title, String message, IconData icon, Color color) {
    showMessageDialog(context,
        title: title, message: message, icon: icon, color: color);
  }

  Future<void> _uploadAvatar(ProfileProvider p) async {
    HapticFeedback.lightImpact();
    final error = await p.uploadAvatar();
    if (error != null && mounted) {
      _popup('Gagal upload', error, Icons.error_outline_rounded,
          context.tokens.danger);
    }
  }

  Future<void> _save(ProfileProvider p) async {
    final t = context.tokens;
    if (_nicknameController.text.trim().isEmpty ||
        _bioController.text.trim().isEmpty) {
      _popup('Form tidak lengkap', 'Nama panggilan dan deskripsi wajib diisi ya.',
          Icons.warning_amber_rounded, t.warning);
      return;
    }
    final error = await p.saveProfile(
        _nicknameController.text.trim(), _bioController.text.trim());
    if (error != null && mounted) {
      _popup('Gagal menyimpan', error, Icons.error_outline_rounded, t.danger);
    }
    // Jika sukses, AuthWrapper mendeteksi nama terisi dan membuka HomeScreen.
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final busy = profile.isLoading && !profile.isUploading;

    return PopScope(
      canPop: false,
      child: AuthScaffold(
        showLogo: false,
        title: 'Selamat datang!',
        subtitle: 'Lengkapi profilmu sebelum memulai.',
        children: [
          Center(
            child: ProfileAvatar(
              avatarUrl: profile.avatarUrl,
              isEditing: true,
              isUploading: profile.isUploading,
              onUpload: () => _uploadAvatar(profile),
            ),
          ),
          const SizedBox(height: Sp.s),
          Center(
              child: Text('Foto profil (opsional)',
                  style: context.text.bodySmall)),
          const SizedBox(height: Sp.xxl),
          TextField(
            controller: _nicknameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Nama panggilan (wajib)',
                prefixIcon: Icon(Icons.badge_rounded)),
          ),
          const SizedBox(height: Sp.m),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Deskripsi singkat (wajib)',
                prefixIcon: Icon(Icons.description_rounded)),
          ),
          const SizedBox(height: Sp.xxl),
          FilledButton(
            onPressed: busy ? null : () => _save(profile),
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: context.tokens.textSecondary))
                : const Text('Simpan & mulai'),
          ),
        ],
      ),
    );
  }
}
