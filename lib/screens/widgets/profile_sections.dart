import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_widgets.dart';

/// Tampilan profil (mode lihat): nama, bio, tombol edit.
class ProfileViewMode extends StatelessWidget {
  final String nickname;
  final String bio;
  final VoidCallback onEdit;

  const ProfileViewMode(
      {super.key,
      required this.nickname,
      required this.bio,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      key: const ValueKey('ViewMode'),
      children: [
        Text(nickname.isNotEmpty ? nickname : 'Pengguna Baru',
            style: context.text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: Sp.s),
        Text(bio.isNotEmpty ? bio : 'Belum ada deskripsi profil.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: t.textSecondary)),
        const SizedBox(height: Sp.l),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            onEdit();
          },
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 48),
              foregroundColor: context.scheme.primary),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit profil'),
        ),
      ],
    );
  }
}

/// Form edit profil (nama panggilan, bio, tombol batal/simpan).
class ProfileEditMode extends StatelessWidget {
  final TextEditingController nicknameController;
  final TextEditingController bioController;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileEditMode({
    super.key,
    required this.nicknameController,
    required this.bioController,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('EditMode'),
      children: [
        TextFormField(
          controller: nicknameController,
          decoration: const InputDecoration(
              labelText: 'Nama panggilan', prefixIcon: Icon(Icons.badge_rounded)),
        ),
        const SizedBox(height: Sp.l),
        TextFormField(
          controller: bioController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Deskripsi diri / bio',
              prefixIcon: Icon(Icons.description_rounded)),
        ),
        const SizedBox(height: Sp.xl),
        Row(children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCancel();
              },
              style: TextButton.styleFrom(
                  foregroundColor: context.tokens.textSecondary),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: Sp.m),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: isLoading ? null : onSave,
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: context.scheme.onPrimary, strokeWidth: 2.5))
                  : const Text('Simpan'),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Kelompok pengaturan dalam satu kartu dengan pemisah hairline.
class SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const SettingsGroup({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Sp.xs),
          child: SectionLabel(label),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: Sp.l, endIndent: Sp.l),
              children[i],
            ],
          ]),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      onTap: onTap,
      minTileHeight: 64,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: context.scheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: t.textSecondary),
    );
  }
}

/// Tombol keluar akun dengan dialog konfirmasi.
class LogoutButton extends StatelessWidget {
  final VoidCallback onConfirmed;
  const LogoutButton({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Keluar akun?'),
            content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),
            actions: [
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: t.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: t.danger),
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirmed();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
      style: TextButton.styleFrom(foregroundColor: t.danger),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Keluar akun'),
    );
  }
}
