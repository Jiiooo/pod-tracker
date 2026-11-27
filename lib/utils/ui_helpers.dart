import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

/// Dialog konfirmasi singkat (ikon + pesan) yang menutup sendiri.
/// Future selesai setelah dialog tertutup; pemanggil tidak perlu pop dialog.
Future<void> showActionAnimation(
    BuildContext context, String message, IconData icon, Color color) {
  HapticFeedback.mediumImpact();
  final navigator = Navigator.of(context, rootNavigator: true);
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    pageBuilder: (_, _, _) => const SizedBox(),
    transitionBuilder: (ctx, anim, _, _) {
      final curved = CurvedAnimation(parent: anim, curve: Motion.curve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Center(
            child: Material(
              color: ctx.scheme.surface,
              borderRadius: BorderRadius.circular(Rd.dialog),
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(Sp.xxl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Rd.dialog),
                  border: Border.all(color: ctx.tokens.outline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 36),
                    ),
                    const SizedBox(height: Sp.l),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: ctx.text.titleMedium),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: Motion.normal,
  );
  return Future.delayed(const Duration(milliseconds: 1200), () {
    if (navigator.mounted) navigator.pop();
  });
}

/// Dialog pesan standar (ikon + judul + isi + tombol "Mengerti").
Future<void> showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color color,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: Sp.m),
        Expanded(child: Text(title, style: ctx.text.titleMedium)),
      ]),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
      ],
    ),
  );
}
