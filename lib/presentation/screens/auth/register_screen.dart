import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      final userProvider = context.read<UserProvider>();
      final walletProvider = context.read<WalletProvider>();
      userProvider.setUser(authProvider.currentUser!);
      await walletProvider.loadWallet(authProvider.currentUser!.id);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (authProvider.errorMessage?.toLowerCase().contains('verifikasi') ?? false) {
      // Email verification required
      if (mounted) {
        showSpSnackbar(context, authProvider.errorMessage ?? '', isError: false);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      showSpSnackbar(
        context,
        authProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      final userProvider = context.read<UserProvider>();
      final walletProvider = context.read<WalletProvider>();
      userProvider.setUser(authProvider.currentUser!);
      await walletProvider.loadWallet(authProvider.currentUser!.id);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (authProvider.errorMessage != null) {
      showSpSnackbar(context, authProvider.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bergabung dengan Planney sekarang',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    SpTextField(
                      label: AppStrings.fullName,
                      hint: 'Nama lengkap kamu',
                      controller: _fullNameController,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Nama lengkap'),
                      prefix: const Icon(Icons.person_outline,
                          color: AppColors.textHint),
                    ),
                    const SizedBox(height: 16),
                    SpTextField(
                      label: AppStrings.username,
                      hint: 'username_kamu',
                      controller: _usernameController,
                      validator: Validators.validateUsername,
                      prefix: const Icon(Icons.alternate_email,
                          color: AppColors.textHint),
                    ),
                    const SizedBox(height: 16),
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
                    ),
                    const SizedBox(height: 16),
                    SpTextField(
                      label: AppStrings.confirmPassword,
                      hint: 'Ulangi kata sandi',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (v) => Validators.validateConfirmPassword(
                          v, _passwordController.text),
                      prefix: const Icon(Icons.lock_outline,
                          color: AppColors.textHint),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    SpButton(
                      text: AppStrings.register,
                      onPressed: _register,
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
                      text: AppStrings.registerWithGoogle,
                      onPressed: _registerWithGoogle,
                      isOutlined: true,
                      isLoading: isLoading,
                      prefix: const Icon(Icons.g_mobiledata,
                          color: AppColors.primary, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.hasAccount,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      AppStrings.loginHere,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
