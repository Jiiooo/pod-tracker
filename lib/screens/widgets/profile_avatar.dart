import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pod_tracker/utils/photo_storage.dart';

/// Avatar profil dengan tombol kamera saat mode edit.
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withValues(alpha: isEditing ? 0.8 : 0.2), width: isEditing ? 3 : 2), boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.3), blurRadius: 20, spreadRadius: isEditing ? 5 : 2, offset: const Offset(0, 8))]),
            child: GestureDetector(
              onTap: () {
                if (avatarUrl != null) {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenAvatarView(imageUrl: avatarUrl!)));
                }
              },
              child: Hero(
                tag: 'profile_avatar_hero',
                child: CircleAvatar(
                  radius: 65, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: avatarUrl == null ? Icon(Icons.person, size: 65, color: Colors.grey.shade400) : ClipOval(child: StoragePhoto(value: avatarUrl!, fit: BoxFit.cover, width: 130, height: 130)),
                ),
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              bottom: 0, right: 4,
              child: GestureDetector(
                onTap: isUploading ? null : onUpload,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
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
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: Hero(tag: 'profile_avatar_hero', child: InteractiveViewer(child: StoragePhoto(value: imageUrl, fit: BoxFit.contain)))),
    );
  }
}
