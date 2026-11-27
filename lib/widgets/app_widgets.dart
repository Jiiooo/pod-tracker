import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

String formatRupiah(num value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp $buf';
}

/// Kartu standar: surface + hairline outline (+ bayangan lembut di light).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.l),
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Rd.cardR,
        border: Border.all(color: t.outline),
        boxShadow: t.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: Rd.cardR,
        clipBehavior: clipBehavior,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Efek skala 0.98 saat ditekan.
class PressScale extends StatefulWidget {
  final Widget child;
  const PressScale({super.key, required this.child});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: Motion.of(context, const Duration(milliseconds: 120)),
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.s),
        child: Text(text.toUpperCase(),
            style: context.text.labelSmall
                ?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
      );
}

/// Pil kecil untuk spesifikasi (Ω, W, airflow).
class StatPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const StatPill(this.text, {super.key, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = color ?? context.scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.xs),
      decoration:
          BoxDecoration(color: t.surfaceRaised, borderRadius: Rd.chipR),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color ?? t.textSecondary),
          const SizedBox(width: Sp.xs),
        ],
        Text(text,
            style: context.text.labelMedium?.copyWith(
                fontSize: 12,
                color: fg,
                fontFeatures: AppTokens.tabular)),
      ]),
    );
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  const RatingStars(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Rating ${rating.toStringAsFixed(1)} dari 5',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: rating >= i - 0.5 ? t.warning : t.outline,
          ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration:
                  BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: context.scheme.primary),
            ),
            const SizedBox(height: Sp.xl),
            Text(title,
                style: context.text.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: Sp.s),
            Text(message,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium
                    ?.copyWith(color: t.textSecondary)),
            if (actionLabel != null) ...[
              const SizedBox(height: Sp.xxl),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.xxl)),
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Isi layar dengan lebar maksimum (tablet/desktop) dan rata tengah.
class MaxWidth extends StatelessWidget {
  final double width;
  final Widget child;
  const MaxWidth({super.key, this.width = 420, required this.child});

  @override
  // heightFactor: 1 so it never grows taller than its child (e.g. inside
  // Scaffold.bottomNavigationBar it would otherwise fill the whole screen).
  Widget build(BuildContext context) => Center(
      heightFactor: 1,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width), child: child));
}
