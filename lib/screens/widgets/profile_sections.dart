import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tampilan profil (mode lihat): nama, bio, tombol edit.
class ProfileViewMode extends StatelessWidget {
  final String nickname;
  final String bio;
  final VoidCallback onEdit;

  const ProfileViewMode({super.key, required this.nickname, required this.bio, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bioText = bio.isNotEmpty ? bio : 'Belum ada deskripsi profil.';

    return Column(
      key: const ValueKey('ViewMode'),
      children: [
        Text(
          nickname.isNotEmpty ? nickname : 'Pengguna Baru',
          style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5), textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: Text(bioText, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor.withValues(alpha: 0.7), height: 1.5), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50, width: 200,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onEdit();
            },
            icon: const Icon(Icons.edit_rounded, size: 18), label: Text('Edit Profil', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      key: const ValueKey('EditMode'),
      children: [
        PremiumTextField(controller: nicknameController, label: 'Nama Panggilan', icon: Icons.badge_rounded, isDark: isDark),
        const SizedBox(height: 20),
        PremiumTextField(controller: bioController, label: 'Deskripsi Diri / Bio', icon: Icons.description_rounded, isDark: isDark, maxLines: 3),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: () { HapticFeedback.lightImpact(); onCancel(); },
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.7)], begin: Alignment.centerLeft, end: Alignment.centerRight), boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]),
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: isLoading
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
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      ),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade100;
    return TextFormField(
      controller: controller, maxLines: maxLines, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        prefixIcon: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 18), child: Icon(icon, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)))]),
        filled: true, fillColor: fillColor, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      ),
    );
  }
}

/// Tombol keluar akun dengan dialog konfirmasi.
class LogoutButton extends StatelessWidget {
  final VoidCallback onConfirmed;
  const LogoutButton({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
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
                ElevatedButton(onPressed: () { Navigator.pop(ctx); onConfirmed(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.2), foregroundColor: Colors.redAccent, elevation: 0), child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), label: Text('Keluar Akun', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
