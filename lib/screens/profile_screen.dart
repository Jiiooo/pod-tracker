import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/csv_codec.dart';
import '../providers/pod_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';
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

  void _showPopup(String title, String message, IconData icon, Color color) {
    showMessageDialog(context,
        title: title, message: message, icon: icon, color: color);
  }

  Future<void> _handleSave(ProfileProvider provider) async {
    HapticFeedback.lightImpact();
    final error = await provider.saveProfile(_nicknameController.text, _bioController.text);

    if (mounted) {
      if (error == null) {
        setState(() => _isEditing = false);
        _showPopup('Berhasil', 'Profil kamu berhasil disimpan ke awan.', Icons.check_circle_outline_rounded, context.tokens.success);
      } else {
        _showPopup('Gagal Menyimpan', error, Icons.error_outline_rounded, context.tokens.danger);
      }
    }
  }

  Future<void> _handleUpload(ProfileProvider provider) async {
    final error = await provider.uploadAvatar();
    if (mounted && error != null) {
      _showPopup('Gagal Upload', error, Icons.error_outline_rounded, context.tokens.danger);
    } else if (mounted && error == null && provider.avatarUrl != null) {
      _showPopup('Berhasil', 'Foto profil berhasil diperbarui.', Icons.check_circle_outline_rounded, context.tokens.success);
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
    final t = context.tokens;
    final provider = context.watch<ProfileProvider>();
    if (provider.isLoading && provider.avatarUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaxWidth(
      width: 560,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.xxl),
        children: [
          Center(
            child: ProfileAvatar(
              avatarUrl: provider.avatarUrl,
              isEditing: _isEditing,
              isUploading: provider.isUploading,
              onUpload: () => _handleUpload(provider),
            ),
          ),
          const SizedBox(height: Sp.l),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.normal),
            switchInCurve: Motion.curve,
            switchOutCurve: Motion.curve,
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
          if (!_isEditing) ...[
            const SizedBox(height: Sp.xxxl),
            const SettingsGroup(label: 'Tampilan', children: [_ThemeModeTile()]),
            const SizedBox(height: Sp.xl),
            SettingsGroup(label: 'Manajemen data', children: [
              SettingsTile(
                title: 'Backup & export data',
                subtitle: 'Simpan semua catatan ke file CSV',
                icon: Icons.download_rounded,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    await context.read<PodProvider>().exportToCSV();
                  } catch (e) {
                    if (context.mounted) {
                      _showPopup('Gagal export', e.toString(),
                          Icons.error_outline_rounded, t.danger);
                    }
                  }
                },
              ),
              SettingsTile(
                title: 'Import dari CSV',
                subtitle: 'Tambahkan catatan dari file CSV hasil backup',
                icon: Icons.upload_file_rounded,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    final result =
                        await context.read<PodProvider>().importFromCSV();
                    if (result != null && context.mounted) {
                      _showImportSummary(result);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showPopup('Gagal import', e.toString(),
                          Icons.error_outline_rounded, t.danger);
                    }
                  }
                },
              ),
            ]),
            const SizedBox(height: Sp.xl),
            Center(child: LogoutButton(onConfirmed: () => _handleLogout(context))),
          ],
        ],
      ),
    );
  }

  void _showImportSummary(CsvImportResult r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hasil Import'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Berhasil diimpor: ${r.configs.length}'),
              Text('Dilewati: ${r.skipped.length}'),
              if (r.skipped.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final s in r.skipped.take(20)) Text('• Baris ${s.row}: ${s.reason}', style: context.text.bodySmall),
                if (r.skipped.length > 20) Text('…dan ${r.skipped.length - 20} lainnya', style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}


class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeProvider, ThemeMode>((t) => t.themeMode);
    return Padding(
      padding: const EdgeInsets.all(Sp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: context.text.titleSmall),
          const SizedBox(height: Sp.m),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('Sistem')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Terang')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Gelap')),
              ],
              selected: {mode},
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                context.read<ThemeProvider>().setThemeMode(s.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
