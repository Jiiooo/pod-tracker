import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showActionAnimation(BuildContext context, String message, IconData icon, Color color) {
  HapticFeedback.mediumImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    pageBuilder: (_, _, _) => const SizedBox(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        child: AlertDialog(
          backgroundColor: Colors.transparent, elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 64)),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
  final navigator = Navigator.of(context, rootNavigator: true);
  Future.delayed(const Duration(milliseconds: 1200), () {
    if (navigator.mounted) navigator.pop();
  });
}