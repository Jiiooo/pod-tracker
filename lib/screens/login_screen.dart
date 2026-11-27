import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../utils/ui_helpers.dart';
import '../widgets/auth_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _popup(String title, String message, IconData icon, Color color) {
    showMessageDialog(context,
        title: title, message: message, icon: icon, color: color);
  }

  Future<void> _enterApp() async {
    await context.read<ProfileProvider>().loadProfile();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  Future<void> _loginEmail() async {
    final auth = context.read<AuthProvider>();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _popup('Form tidak lengkap',
          'Email dan password wajib diisi untuk melanjutkan.',
          Icons.warning_amber_rounded, context.tokens.warning);
      return;
    }
    final error = await auth.loginWithEmail(
        _emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    if (error == null) {
      await _enterApp();
    } else {
      var msg = error;
      if (error.toLowerCase().contains('invalid login credentials')) {
        msg = 'Email atau password yang kamu masukkan salah. Silakan periksa kembali.';
      }
      _popup('Login gagal', msg, Icons.error_outline_rounded,
          context.tokens.danger);
    }
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final error = await auth.authenticateWithGoogle(isLogin: true);
    if (error == 'SILENT_CANCEL' || !mounted) return;
    if (error == null) {
      await _enterApp();
    } else {
      _popup('Gagal masuk', error, Icons.error_outline_rounded,
          context.tokens.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<AuthProvider, bool>((a) => a.isLoading);
    final t = context.tokens;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return AuthScaffold(
      title: 'Pod Tracker',
      subtitle: 'Masuk ke akunmu untuk sinkronisasi real-time',
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              labelText: 'Alamat email', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: Sp.m),
        TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => isLoading ? null : _loginEmail(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscureText ? 'Tampilkan password' : 'Sembunyikan password',
              icon: Icon(_obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
        ),
        const SizedBox(height: Sp.xl),
        FilledButton(
          onPressed: isLoading ? null : _loginEmail,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: t.textSecondary))
              : const Text('Masuk'),
        ),
        const SizedBox(height: Sp.xl),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.l),
            child: Text('atau', style: context.text.bodySmall),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: Sp.xl),
        GoogleButton(
            label: 'Lanjutkan dengan Google',
            onPressed: isLoading ? null : _loginGoogle),
        const SizedBox(height: Sp.l),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: Text.rich(TextSpan(
            text: 'Belum punya akun? ',
            style: context.text.bodyMedium?.copyWith(color: t.textSecondary),
            children: [
              TextSpan(
                  text: 'Daftar di sini',
                  style: context.text.labelLarge
                      ?.copyWith(color: context.scheme.primary)),
            ],
          )),
        ),
      ],
    );
  }
}
