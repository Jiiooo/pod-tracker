import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';

import 'models/pod_config.dart';

import 'providers/pod_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/auth_provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/mandatory_profile_screen.dart';

Future<void> _initLocal() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PodConfigAdapter());
  await Future.wait([
    Hive.openBox<PodConfig>('podBox'),
    Hive.openBox(ThemeProvider.boxName),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive (lokal) dan Supabase diinisialisasi bersamaan.
  await Future.wait([
    _initLocal(),
    Supabase.initialize(
      url: 'https://ljwvsgcvmbndidedrqwt.supabase.co',
      publishableKey: 'sb_publishable_J2_mN79g9W5-AYRDyR98QQ_QWypXhOq',
    ),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => PodProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) => CatalogProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ==========================================
// KELAS UTAMA APLIKASI (MY APP)
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeProvider, ThemeMode>((t) => t.themeMode);
    return MaterialApp(
      title: 'Pod Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// AUTH WRAPPER (Pengatur Arah Setelah Splash Screen)
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan loading screen saat sedang memeriksa session
          return const _LoadingScaffold();
        }

        // Jika ada sesi login yang aktif
        if (snapshot.hasData && snapshot.data!.session != null) {

          // 👇 INI ADALAH LOGIKA "SATPAM" YANG TERLEWAT 👇
          return Consumer<ProfileProvider>(
            builder: (context, profile, child) {

              // 1. Tunggu provider mengambil data profil dari Supabase
              if (profile.isLoading) {
                return const _LoadingScaffold();
              }

              // 2. CEGAT! Jika nama kosong, paksa arahkan ke halaman form profil
              if (profile.nickname.isEmpty) {
                return const MandatoryProfileScreen();
              }

              // 3. Jika nama sudah ada (profil lengkap), izinkan masuk Home
              return const HomeScreen();
            },
          );
        }

        // --- USER LOGOUT ATAU BELUM LOGIN ---
        return const LoginScreen();
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
