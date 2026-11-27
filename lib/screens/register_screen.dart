import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/ui_helpers.dart';
import '../widgets/auth_scaffold.dart';
import 'set_password_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  Future<void> _register(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final error = await auth.authenticateWithGoogle(isLogin: false);
    if (error == 'SILENT_CANCEL' || !context.mounted) return;
    if (error == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SetPasswordScreen()));
    } else {
      showMessageDialog(context,
          title: 'Pendaftaran ditolak',
          message: error,
          icon: Icons.warning_amber_rounded,
          color: context.tokens.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);
    return AuthScaffold(
      title: 'Daftar akun baru',
      subtitle:
          'Cukup satu ketukan dengan akun Google untuk mengaktifkan sinkronisasi awan.',
      leading: IconButton(
        tooltip: 'Kembali',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : GoogleButton(
                label: 'Daftar dengan Google',
                onPressed: () => _register(context)),
      ],
    );
  }
}
