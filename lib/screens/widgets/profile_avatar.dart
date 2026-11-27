import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/photo_storage.dart';

/// Avatar profil 88px dengan tombol kamera saat mode edit.
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isEditing;
  final bool isUploading;
  final VoidCallback onUpload;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.isEditing,
    required this.isUploading,
    required this.onUpload,
  });

  static const double size = 88;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = context.scheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: avatarUrl == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                FullScreenAvatarView(imageUrl: avatarUrl!)));
                  },
            child: Hero(
              tag: 'profile_avatar_hero',
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.surfaceRaised,
                  border: Border.all(
                      color: isEditing ? scheme.primary : t.outline,
                      width: isEditing ? 2 : 1),
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person_rounded,
                        size: 44, color: t.textSecondary)
                    : StoragePhoto(
                        value: avatarUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size),
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              bottom: -4,
              right: -4,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Material(
                    color: scheme.primary,
                    shape: CircleBorder(
                        side: BorderSide(color: scheme.surface, width: 3)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isUploading ? null : onUpload,
                      child: Padding(
                        padding: const EdgeInsets.all(Sp.s),
                        child: isUploading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: scheme.onPrimary, strokeWidth: 2))
                            : Icon(Icons.camera_alt_rounded,
                                color: scheme.onPrimary,
                                size: 18,
                                semanticLabel: 'Ganti foto profil'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.dark.textPrimary,
        iconTheme: IconThemeData(color: AppColors.dark.textPrimary),
      ),
      body: Center(
        child: Hero(
          tag: 'profile_avatar_hero',
          child: InteractiveViewer(
              child: StoragePhoto(value: imageUrl, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
