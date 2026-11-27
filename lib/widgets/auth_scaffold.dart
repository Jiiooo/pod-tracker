import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'app_widgets.dart';

/// Logo dengan satu glow aksen yang halus (hero login/splash).
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final accent = context.scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [accent.withValues(alpha: 0.22), Colors.transparent],
          stops: const [0.0, 1.0],
          radius: 0.75,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: Image.asset('assets/logo_foreground.png', fit: BoxFit.contain),
      ),
    );
  }
}

/// Kerangka layar autentikasi: kolom tengah maks 420, logo, judul, subjudul.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? leading;
  final bool showLogo;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.leading,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: leading == null
          ? null
          : AppBar(automaticallyImplyLeading: false, leading: leading),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
                horizontal: Sp.xxl, vertical: Sp.xxxl),
            child: MaxWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo)
                    const Center(child: BrandLogo()),
                  if (showLogo) const SizedBox(height: Sp.xl),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: context.text.displayMedium),
                  const SizedBox(height: Sp.s),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium
                          ?.copyWith(color: t.textSecondary)),
                  const SizedBox(height: Sp.xxxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Google (OutlinedButton + logo dari aset).
class GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GoogleButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Image.asset('assets/google_g.png', width: 22, height: 22),
      label: Text(label),
    );
  }
}
