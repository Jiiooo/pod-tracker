import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart'; // 👇 Import Profil Provider
import '../main.dart'; // 👇 Import main.dart untuk memanggil AuthWrapper
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../utils/ui_helpers.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _popup(String title, String message, IconData icon, Color color) {
    showMessageDialog(context,
        title: title, message: message, icon: icon, color: color);
  }

  Future<void> _backToLogin() async {
    await context.read<AuthProvider>().cancelRegistration();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final t = context.tokens;
    if (_passwordController.text.length < 6) {
      _popup('Password lemah', 'Password minimal harus terdiri dari 6 karakter.',
          Icons.shield_outlined, t.warning);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _popup(
          'Validasi gagal',
          'Kolom konfirmasi password tidak sesuai dengan password yang kamu masukkan.',
          Icons.warning_amber_rounded,
          t.danger);
      return;
    }
    final error = await auth.setPassword(_passwordController.text.trim());
    if (!mounted) return;
    if (error == null) {
      await context.read<ProfileProvider>().loadProfile();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } else {
      _popup('Gagal menyimpan', error, Icons.error_outline_rounded, t.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);
    final toggle = IconButton(
      tooltip: _obscureText ? 'Tampilkan password' : 'Sembunyikan password',
      icon: Icon(_obscureText
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined),
      onPressed: () => setState(() => _obscureText = !_obscureText),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin();
      },
      child: AuthScaffold(
        title: 'Langkah terakhir',
        subtitle:
            'Karena kamu mendaftar dengan Google, buat password agar kamu juga bisa login dengan email & password.',
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToLogin,
        ),
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
                labelText: 'Password baru (min. 6 karakter)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: toggle),
          ),
          const SizedBox(height: Sp.m),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureText,
            onSubmitted: (_) => isLoading ? null : _submit(),
            decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
                prefixIcon: Icon(Icons.lock_reset_rounded)),
          ),
          const SizedBox(height: Sp.xxl),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: context.tokens.textSecondary))
                : const Text('Simpan & masuk'),
          ),
        ],
      ),
    );
  }
}
