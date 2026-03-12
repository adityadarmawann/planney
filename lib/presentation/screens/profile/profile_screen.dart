import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/sp_card.dart';
import '../../widgets/common/sp_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAvatarLoading = false;

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isAvatarLoading = true);
      final bytes = await picked.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final avatarUrl = await userProvider.uploadAvatar(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
      );

      if (avatarUrl == null) {
        if (!mounted) return;
        showSpSnackbar(
          context,
          userProvider.errorMessage ?? 'Gagal upload foto profil',
          isError: true,
        );
        return;
      }

      final success = await userProvider.updateProfile(
        userId: userId,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;
      if (success) {
        showSpSnackbar(context, 'Foto profil berhasil diperbarui', isSuccess: true);
      } else {
        showSpSnackbar(
          context,
          userProvider.errorMessage ?? 'Gagal menyimpan foto profil',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showSpSnackbar(context, 'Terjadi kesalahan saat memilih foto', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Foto Profil'),
        content: Text('Yakin ingin menghapus foto profil Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isAvatarLoading = true);
      final success = await userProvider.deleteAvatar(userId: userId);

      if (!mounted) return;
      if (success) {
        // Clear image cache to ensure UI updates immediately
        imageCache.clear();
        imageCache.clearLiveImages();
        showSpSnackbar(context, 'Foto profil berhasil dihapus', isSuccess: true);
      } else {
        showSpSnackbar(
          context,
          userProvider.errorMessage ?? 'Gagal menghapus foto profil',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showSpSnackbar(context, 'Terjadi kesalahan saat menghapus foto', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
      }
    }
  }

  void _showAvatarSourcePicker() {
    final userProvider = context.read<UserProvider>();
    final hasAvatar = userProvider.user?.avatarUrl != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined),
                title: Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined),
                title: Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              if (hasAvatar)
                const Divider(height: 1, color: AppColors.divider),
              if (hasAvatar)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Hapus Foto Profil',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final wallet = context.watch<WalletProvider>().wallet;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Avatar section
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: user?.avatarUrl != null
                      ? () => _showAvatarPreview(user!.avatarUrl!)
                      : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.secondaryLight.withValues(alpha: 0.25),
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: _isAvatarLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : user?.avatarUrl == null
                            ? Text(
                                (user?.fullName.isNotEmpty == true
                                        ? user!.fullName[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              )
                            : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: InkWell(
                    onTap: _isAvatarLoading ? null : _showAvatarSourcePicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondaryLight.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk foto untuk lihat, ikon kamera untuk ganti',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Pengguna',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user?.username ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Wallet balance chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondaryLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(wallet?.balance ?? 0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Profile info card
          SpCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Nama Lengkap',
                  value: user?.fullName ?? '-',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.alternate_email,
                  label: 'Username',
                  value: '@${user?.username ?? '-'}',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? '-',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: user?.phone ?? 'Belum diisi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Actions card
          SpCard(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profil',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.history,
                  label: 'Riwayat Transaksi',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.history),
                ),
                const Divider(height: 1),
                Consumer<ThemeProvider>(
                  builder: (_, tp, __) {
                    final modeLabel = tp.themeMode == ThemeMode.dark
                        ? 'Dark Mode'
                        : tp.themeMode == ThemeMode.system
                            ? 'Ikuti Sistem'
                            : 'Light Mode';
                    return _MenuTile(
                      icon: Icons.palette_outlined,
                      label: 'Tema Aplikasi',
                      subtitle: modeLabel,
                      onTap: () => _showThemeSelector(context),
                    );
                  },
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.logout,
                  label: 'Keluar',
                  color: AppColors.error,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Planney v1.6.4',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Consumer<ThemeProvider>(
          builder: (ctx, themeProvider, __) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Tema',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ThemeModeTile(
                      icon: Icons.light_mode_outlined,
                      title: 'Light Mode',
                      subtitle: 'Tampilan cerah, bersih, dan lembut',
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () async {
                        await themeProvider.setThemeMode(ThemeMode.light);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 10),
                    _ThemeModeTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Nuansa gelap elegan, nyaman di malam hari',
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () async {
                        await themeProvider.setThemeMode(ThemeMode.dark);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 10),
                    _ThemeModeTile(
                      icon: Icons.contrast_outlined,
                      title: 'Ikuti Sistem',
                      subtitle: 'Menyesuaikan tema dengan pengaturan perangkat',
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () async {
                        await themeProvider.setThemeMode(ThemeMode.system);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar'),
        content: Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: Text('Keluar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.secondary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.secondary : cs.outline.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? cs.secondary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.secondary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? cs.secondary : cs.outline,
            ),
          ],
        ),
      ),
    );
  }
}


class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? cs.onSurfaceVariant, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? cs.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: cs.secondary),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: cs.outline, size: 20),
    );
  }
}
