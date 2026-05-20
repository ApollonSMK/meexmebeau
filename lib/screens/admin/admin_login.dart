import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/l10n.dart';
import '../../providers/providers.dart';
import '../../widgets/gradient_button.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppL10n.of(context, ref);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/admin');
    } catch (e) {
      setState(() {
        _error = l10n.t('Credenciais inválidas', 'Identifiants invalides');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('Admin', 'Admin'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('Painel Admin', 'Panneau Admin'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('Acesso restrito a administradores', 'Accès restreint aux administrateurs'),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color: AppTheme.textMuted,
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: l10n.login,
                  isLoading: _loading,
                  onPressed: _login,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
