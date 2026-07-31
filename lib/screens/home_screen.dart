import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../providers/pod_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';

// --- IMPORT VIEW YANG SUDAH KITA PECAH TADI ---
import 'views/stats_view.dart';
import 'views/archive_view.dart';
import 'views/tracker_view.dart';
import 'info_screen.dart';
import 'profile_screen.dart';
import 'add_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Default ke Tracker yang ada di tengah

  // Memanggil file-file view yang terpisah
  final List<Widget> _pages = const [StatsView(), ArchiveView(), TrackerView(), InfoScreen(), ProfileScreen()];
  final List<String> _titles = const ['Statistik & Biaya', 'Arsip Settingan', 'Tracker Pod', 'Panduan Vaping', 'Profil Saya'];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PodProvider>(context, listen: false).syncData();
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: EdgeInsets.only(top: isSelected ? 0 : 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSelected ? 28 : 24, color: isSelected ? Colors.white : Colors.grey),
          if (!isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required bool isDark, required VoidCallback onTap, String? tooltip}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 22),
        tooltip: tooltip,
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashRadius: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final navBarColor = isDark ? Colors.grey.shade900 : Colors.white;
    final appBarTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 75,
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] : [primaryColor.withOpacity(0.6), primaryColor.withOpacity(0.9)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(color: (isDark ? Colors.black : primaryColor).withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6))],
            ),
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(animation), child: child)),
            child: Text(_titles[_selectedIndex], key: ValueKey<int>(_selectedIndex), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: appBarTextColor)),
          ),

          actions: [
            Consumer<ThemeProvider>(
              builder: (context, theme, child) => _buildAppBarAction(
                icon: theme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                isDark: isDark,
                onTap: () => theme.toggleTheme(!theme.isDarkMode),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 2
          ? Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddConfigScreen()));
          },
          backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex, height: 65, backgroundColor: Colors.transparent, color: navBarColor, buttonBackgroundColor: primaryColor,
        animationDuration: const Duration(milliseconds: 400), animationCurve: Curves.easeOutCubic,
        items: <Widget>[
          _buildNavItem(Icons.insights_rounded, 'Statistik', 0),
          _buildNavItem(Icons.archive_rounded, 'Arsip', 1),
          _buildNavItem(Icons.list_alt_rounded, 'Tracker', 2),
          _buildNavItem(Icons.menu_book_rounded, 'Panduan', 3),
          _buildNavItem(Icons.person_rounded, 'Profil', 4),
        ],
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}