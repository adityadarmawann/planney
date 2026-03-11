import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_text_field.dart';
import '../../widgets/common/sp_snackbar.dart';

enum TransferType { user, bank, qris }

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final user = authProvider.currentUser;
    final wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saldo Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Tersedia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(walletProvider.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Informasi Dompet (with user full name)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Dompet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'Nama Lengkap',
                    value: user?.fullName ?? 'N/A',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Username',
                    value: '@${user?.username ?? 'N/A'}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'No. Rekening',
                    value: wallet != null
                        ? (wallet.id.length >= 8
                            ? wallet.id.substring(0, 8).toUpperCase()
                            : wallet.id.toUpperCase())
                        : 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Top Up Button
            SpButton(
              text: 'Top Up',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.topup),
              isOutlined: false,
            ),
            const SizedBox(height: 16),

            // 4. Transfer Menu (User & Bank)
            const Text(
              'Transfer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TransferCard(
                    icon: Icons.person_outline,
                    title: 'Pengguna',
                    subtitle: 'Transfer ke user lain',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _UserTransferScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TransferCard(
                    icon: Icons.account_balance,
                    title: 'Bank',
                    subtitle: 'Tarik ke rekening',
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _BankTransferScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. PayLater
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PayLater',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Lihat tagihan dan kelola PayLater',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.paylater),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for info rows
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Helper widget for transfer cards
class _TransferCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TransferCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTransferScreen extends StatefulWidget {
  const _UserTransferScreen();

  @override
  State<_UserTransferScreen> createState() => _UserTransferScreenState();
}

class _UserTransferScreenState extends State<_UserTransferScreen> {
  final _usernameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  UserModel? _recipient;
  bool _searching = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      showSpSnackbar(context, 'Masukkan username', isError: true);
      return;
    }

    setState(() {
      _searching = true;
      _recipient = null; // Reset previous search
    });

    try {
      final userRepo = UserRepository(
        client: Supabase.instance.client,
      );

      final user = await userRepo.getUserByUsername(username);
      
      if (!mounted) return;
      
      setState(() {
        _recipient = user;
        _searching = false;
      });

      if (user == null) {
        showSpSnackbar(context, 'Pengguna tidak ditemukan', isError: true);
      } else {
        showSpSnackbar(context, 'Pengguna ditemukan: ${user.fullName}', isError: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recipient = null;
        _searching = false;
      });
      showSpSnackbar(
        context,
        'Terjadi kesalahan: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _transfer() async {
    if (_recipient == null) {
      showSpSnackbar(context, 'Cari penerima terlebih dahulu', isError: true);
      return;
    }

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      showSpSnackbar(context, 'Masukkan jumlah transfer', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final senderId = authProvider.currentUser?.id;
    final senderWalletId = walletProvider.wallet?.id;

    if (senderId == null || senderWalletId == null) return;
    if (senderId == _recipient!.id) {
      showSpSnackbar(context, 'Tidak bisa transfer ke diri sendiri',
          isError: true);
      return;
    }

    if (amount > walletProvider.balance) {
      showSpSnackbar(context, AppStrings.insufficientBalance, isError: true);
      return;
    }

    // Get receiver wallet via RPC (works with strict RLS)
    final walletRepo = WalletRepository(client: Supabase.instance.client);
    final receiverWalletId =
        await walletRepo.getRecipientWalletIdForTransfer(_recipient!.id);
    if (receiverWalletId == null) {
      if (mounted) {
        showSpSnackbar(
          context, 
          'Wallet penerima tidak ditemukan. Pastikan penerima sudah terverifikasi dan wallet aktif.',
          isError: true,
        );
      }
      return;
    }

    // Navigate to confirm screen
    if (!mounted) return;
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.transferConfirm,
      arguments: {
        'type': TransferType.user,
        'recipient': _recipient,
        'amount': amount,
        'note': _noteController.text,
        'senderId': senderId,
        'senderWalletId': senderWalletId,
        'receiverId': _recipient!.id,
        'receiverWalletId': receiverWalletId,
      },
    );

    if (result == true && mounted) {
      await walletProvider.loadWallet(senderId);
      // Pop twice: once for confirm screen, once for user transfer screen
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer ke Pengguna'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Username Penerima',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixText: '@',
                    hintText: 'username_penerima',
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searching ? null : _searchUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
              ),
            ],
          ),
          if (_recipient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLightest,
                    child: Text(
                      _recipient!.fullName[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_recipient!.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('@${_recipient!.username}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Jumlah Transfer',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'Rp ',
              hintText: '0',
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SpTextField(
            label: '${AppStrings.note} (${AppStrings.optional})',
            hint: 'Contoh: Bayar makan siang',
            controller: _noteController,
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          SpButton(
            text: 'Lanjutkan Transfer',
            onPressed: _transfer,
            isLoading: context.watch<TransactionProvider>().isLoading,
          ),
        ],
      ),
    ),
    );
  }
}

class _BankTransferScreen extends StatefulWidget {
  const _BankTransferScreen();

  @override
  State<_BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<_BankTransferScreen> {
  static const double _adminFee = 2500.0;
  String? _selectedBank;
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final List<Map<String, String>> _banks = [
    {'name': 'BCA', 'icon': '🏦'},
    {'name': 'BNI', 'icon': '🏛️'},
    {'name': 'BRI', 'icon': '🏧'},
    {'name': 'Mandiri', 'icon': '💳'},
    {'name': 'CIMB Niaga', 'icon': '🏦'},
    {'name': 'Danamon', 'icon': '🏦'},
    {'name': 'BTN', 'icon': '🏠'},
    {'name': 'BSI', 'icon': '🕌'},
  ];

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    if (_selectedBank == null) {
      showSpSnackbar(context, 'Pilih bank tujuan', isError: true);
      return;
    }
    if (_accountController.text.isEmpty) {
      showSpSnackbar(context, 'Masukkan nomor rekening', isError: true);
      return;
    }
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      showSpSnackbar(context, 'Masukkan jumlah transfer', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final senderId = authProvider.currentUser?.id;
    final senderWalletId = walletProvider.wallet?.id;

    if (senderId == null || senderWalletId == null) return;

    if (amount + _adminFee > walletProvider.balance) {
      showSpSnackbar(context, AppStrings.insufficientBalance, isError: true);
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.transferConfirm,
      arguments: {
        'type': TransferType.bank,
        'bankName': _selectedBank,
        'accountNumber': _accountController.text,
        'amount': amount,
        'fee': _adminFee,
        'note': _noteController.text,
        'senderId': senderId,
        'senderWalletId': senderWalletId,
      },
    );

    if (result == true && mounted) {
      await walletProvider.loadWallet(senderId);
      // Pop twice: once for confirm screen, once for bank transfer screen
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer ke Bank'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Pilih Bank',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: _banks.length,
            itemBuilder: (context, index) {
              final bank = _banks[index];
              final isSelected = _selectedBank == bank['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedBank = bank['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLightest
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(bank['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        bank['name']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SpTextField(
            label: 'Nomor Rekening',
            hint: 'Masukkan nomor rekening',
            controller: _accountController,
            keyboardType: TextInputType.number,
            prefix:
                const Icon(Icons.credit_card, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah Transfer',
              prefixText: 'Rp ',
              hintText: '0',
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              helperText: 'Biaya admin: ${CurrencyFormatter.format(_adminFee)}',
            ),
          ),
          const SizedBox(height: 16),
          SpTextField(
            label: '${AppStrings.note} (${AppStrings.optional})',
            hint: 'Catatan transfer',
            controller: _noteController,
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          SpButton(
            text: 'Lanjutkan Transfer',
            onPressed: _transfer,
            isLoading: context.watch<TransactionProvider>().isLoading,
          ),
        ],
      ),
    ),
    );
  }
}
