import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_text_field.dart';
import '../../widgets/common/sp_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.updateProfile(
      userId: userId,
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      showSpSnackbar(context, 'Profil berhasil diperbarui', isSuccess: true);
      Navigator.pop(context);
    } else {
      showSpSnackbar(
        context,
        userProvider.errorMessage ?? 'Gagal memperbarui profil',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.editProfile),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              SpTextField(
                label: AppStrings.fullName,
                controller: _fullNameController,
                validator: (v) =>
                    Validators.validateRequired(v, 'Nama lengkap'),
                prefix: Icon(Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SpTextField(
                label: AppStrings.username,
                controller: _usernameController,
                validator: Validators.validateUsername,
                prefix: Icon(Icons.alternate_email,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SpTextField(
                label: '${AppStrings.phone} (${AppStrings.optional})',
                hint: '08xxxxxxxxxx',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                prefix: Icon(Icons.phone_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SpButton(
                text: AppStrings.saveChanges,
                onPressed: _save,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
