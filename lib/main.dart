import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/pod_config.dart';

import 'providers/pod_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/auth_provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/mandatory_profile_screen.dart'; // 👇 Sudah ditambahkan titik koma (;)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Database Lokal (Hive)
  await Hive.initFlutter();
  Hive.registerAdapter(PodConfigAdapter());
  await Hive.openBox<PodConfig>('podBox');

  // 2. Inisialisasi Database Cloud (Supabase)
  await Supabase.initialize(
    url: 'https://ljwvsgcvmbndidedrqwt.supabase.co',
    anonKey: 'sb_publishable_J2_mN79g9W5-AYRDyR98QQ_QWypXhOq',
  );

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {

        final brightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;

        return MaterialApp(
          title: 'Pod Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueGrey,
              brightness: brightness,
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData(brightness: brightness).textTheme,
            ),
          ),
          home: const SplashScreen(),
        );
      },
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
          return const Scaffold(
            backgroundColor: Color(0xFF0a0a0a),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }

        // Jika ada sesi login yang aktif
        if (snapshot.hasData && snapshot.data!.session != null) {

          // 👇 INI ADALAH LOGIKA "SATPAM" YANG TERLEWAT 👇
          return Consumer<ProfileProvider>(
            builder: (context, profile, child) {

              // 1. Tunggu provider mengambil data profil dari Supabase
              if (profile.isLoading) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0a0a0a),
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
                );
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