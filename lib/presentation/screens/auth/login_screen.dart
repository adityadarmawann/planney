import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_text_field.dart';
import '../../widgets/common/sp_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    // Listen untuk auth state changes (e.g., dari Google OAuth redirect)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      
      final session = data.session;
      if (session != null) {
        // User berhasil login, load user data dan navigate ke home
        try {
          final userProvider = context.read<UserProvider>();
          final authProvider = context.read<AuthProvider>();
          final walletProvider = context.read<WalletProvider>();
          
          await userProvider.loadUser(session.user.id);
          if (userProvider.user != null) {
            authProvider.setUser(userProvider.user);
            await walletProvider.loadWallet(session.user.id);
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          }
        } catch (e) {
          if (mounted) {
            showSpSnackbar(
              context,
              'Gagal load user data: ${e.toString()}',
              isError: true,
            );
          }
        }
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      final userProvider = context.read<UserProvider>();
      final walletProvider = context.read<WalletProvider>();
      userProvider.setUser(authProvider.currentUser!);
      await walletProvider.loadWallet(authProvider.currentUser!.id);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      showSpSnackbar(
        context,
        authProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    // Google OAuth adalah async flow dengan redirect
    // Jangan menunggu currentUser di sini
    // Auth state listener akan handle redirect dan update secara otomatis
    if (!success && authProvider.errorMessage != null) {
      showSpSnackbar(context, authProvider.errorMessage!, isError: true);
    }
    // Jika success=true, OAuth flow sudah di-launch
    // User akan di-redirect, dan auth state akan update otomatis
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo-planney.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Selamat Datang! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke akun Planney kamu',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    SpTextField(
                      label: AppStrings.email,
                      hint: 'contoh@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      prefix: const Icon(Icons.email_outlined,
                          color: AppColors.textHint),
                    ),
                    const SizedBox(height: 16),
                    SpTextField(
                      label: AppStrings.password,
                      hint: 'Minimal 8 karakter',
                      controller: _passwordController,
                      obscureText: true,
                      validator: Validators.validatePassword,
                      prefix: const Icon(Icons.lock_outline,
                          color: AppColors.textHint),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(AppStrings.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SpButton(
                      text: AppStrings.login,
                      onPressed: _login,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'atau',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SpButton(
                      text: AppStrings.loginWithGoogle,
                      onPressed: _loginWithGoogle,
                      isOutlined: true,
                      isLoading: isLoading,
                      prefix: const Icon(Icons.g_mobiledata,
                          color: AppColors.primary, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.noAccount,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text(
                      AppStrings.registerHere,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
