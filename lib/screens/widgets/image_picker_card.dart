import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/photo_storage.dart';

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + 6, metric.length)), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Kartu foto botol liquid: foto (cloud/lokal) atau area dengan garis putus-putus.
class ImagePickerCard extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const ImagePickerCard(
      {super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final has = imagePath != null;
    return Semantics(
      button: true,
      label: has ? 'Ubah foto liquid' : 'Tambah foto liquid',
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: Rd.cardR,
          child: Material(
            color: has ? t.surfaceRaised : context.scheme.surface,
            child: InkWell(
              onTap: onTap,
              child: has
                  ? Stack(fit: StackFit.expand, children: [
                      StoragePhoto(value: imagePath!, fit: BoxFit.cover),
                      Positioned(
                        right: Sp.m,
                        bottom: Sp.m,
                        child: Container(
                          padding: const EdgeInsets.all(Sp.s),
                          decoration: BoxDecoration(
                              color: context.scheme.surface,
                              shape: BoxShape.circle),
                          child: Icon(Icons.edit_rounded,
                              size: 18, color: context.scheme.onSurface),
                        ),
                      ),
                    ])
                  : CustomPaint(
                      painter: _DashedBorderPainter(t.outline, Rd.card),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: t.accentSoft, shape: BoxShape.circle),
                              child: Icon(Icons.add_a_photo_outlined,
                                  color: context.scheme.primary),
                            ),
                            const SizedBox(height: Sp.m),
                            Text('Tambah foto liquid',
                                style: context.text.labelLarge),
                            const SizedBox(height: 2),
                            Text('Opsional', style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ),
            ),
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
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil dari kamera'),
            onTap: () {
              Navigator.pop(ctx);
              onCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () {
              Navigator.pop(ctx);
              onGallery();
            },
          ),
          if (hasImage)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: ctx.tokens.danger),
              title: Text('Hapus foto', style: TextStyle(color: ctx.tokens.danger)),
              onTap: () {
                Navigator.pop(ctx);
                onRemove();
              },
            ),
          const SizedBox(height: Sp.s),
        ],
      ),
    ),
  );
}
