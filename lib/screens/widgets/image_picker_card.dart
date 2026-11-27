import 'package:flutter/material.dart';
import 'package:pod_tracker/utils/photo_storage.dart';

/// Kartu foto botol liquid: menampilkan foto (cloud/lokal) atau placeholder.
class ImagePickerCard extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const ImagePickerCard({super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
          ),
          clipBehavior: Clip.hardEdge,
          child: imagePath != null
              ? StoragePhoto(value: imagePath!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('Tambah Foto Liquid', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bottom sheet pilihan sumber foto (kamera / galeri / hapus).
void showImageSourceSheet({
  required BuildContext context,
  required bool hasImage,
  required VoidCallback onCamera,
  required VoidCallback onGallery,
  required VoidCallback onRemove,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Ambil dari Kamera'),
            onTap: () {
              Navigator.pop(ctx);
              onCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari Galeri'),
            onTap: () {
              Navigator.pop(ctx);
              onGallery();
            },
          ),
          if (hasImage)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onRemove();
              },
            ),
        ],
      ),
    ),
  );
}
