import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/auth_scaffold.dart';

import '../main.dart'; // Import AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 1. ANIMASI DIPERLAMBAT (Menjadi 1500ms / 1.5 detik) agar terasa lebih anggun
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // 2. WAKTU TUNGGU DIPERLAMBAT (Menjadi 2500ms / 2.5 detik) agar teks sempat terbaca
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => const AuthWrapper(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash selalu gelap agar menyatu dengan splash native.
    return Theme(
      data: AppTheme.dark,
      child: Builder(builder: (context) {
        final t = context.tokens;
        return Scaffold(
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 128),
                    const SizedBox(height: Sp.xxl),
                    Text('POD TRACKER',
                        style: context.text.displayMedium
                            ?.copyWith(fontSize: 26, letterSpacing: 6)),
                    const SizedBox(height: Sp.s),
                    Text('Precision Cloud Analytics',
                        style: context.text.bodySmall?.copyWith(
                            color: t.textSecondary, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
