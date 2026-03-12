import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/thousand_separator_formatter.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_snackbar.dart';
import 'transfer_screen.dart';

class QrisPaymentScreen extends StatefulWidget {
  const QrisPaymentScreen({super.key});

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  late String _imagePath;
  final TextEditingController _amountController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _imagePath = args?['imagePath'] ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _proceed() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      showSpSnackbar(context, 'Masukkan jumlah pembayaran', isError: true);
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      final senderId = authProvider.currentUser?.id;
      final senderWalletId = walletProvider.wallet?.id;

      if (senderId == null || senderWalletId == null) {
        showSpSnackbar(context, 'Data wallet tidak ditemukan', isError: true);
        return;
      }

      final amount = CurrencyFormatter.parse(amountText);
      if (amount <= 0) {
        showSpSnackbar(context, 'Jumlah harus lebih dari 0', isError: true);
        return;
      }

      // Tidak perlu validasi saldo wallet di sini karena user bisa pilih PayLater
      // di halaman konfirmasi jika saldo tidak cukup

      // Navigate to transfer confirm screen with QRIS type
      Navigator.pushNamed(
        context,
        AppRoutes.transferConfirm,
        arguments: {
          'type': TransferType.qris,
          'amount': amount,
          'fee': 0.0,
          'merchant': 'Warung UMKM Indonesia',
          'merchantIcon': _imagePath,
          'note': '',
          'senderId': senderId,
          'senderWalletId': senderWalletId,
        },
      );
    } catch (e) {
      showSpSnackbar(context, 'Jumlah tidak valid', isError: true);
    }
  }

  void _setAmount(double amount) {
    final formatted = CurrencyFormatter.formatAsPlainText(amount);
    setState(() {
      _amountController.text = formatted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran QRIS'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // QR/Image Preview
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Merchant Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merchant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Warung UMKM Indonesia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Amount Input
              Text(
                'Jumlah Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                inputFormatters: [ThousandSeparatorFormatter()],
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick amount buttons
              Text(
                'Pilihan Cepat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _QuickAmountButton(
                    label: 'Rp 5.000',
                    amount: 5000,
                    onTap: () => _setAmount(5000),
                  ),
                  _QuickAmountButton(
                    label: 'Rp 25.000',
                    amount: 25000,
                    onTap: () => _setAmount(25000),
                  ),
                  _QuickAmountButton(
                    label: 'Rp 50.000',
                    amount: 50000,
                    onTap: () => _setAmount(50000),
                  ),
                  _QuickAmountButton(
                    label: 'Rp 100.000',
                    amount: 100000,
                    onTap: () => _setAmount(100000),
                  ),
                  _QuickAmountButton(
                    label: 'Rp 250.000',
                    amount: 250000,
                    onTap: () => _setAmount(250000),
                  ),
                  _QuickAmountButton(
                    label: 'Rp 1.000.000',
                    amount: 1000000,
                    onTap: () => _setAmount(1000000),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(
                        CurrencyFormatter.parse(_amountController.text),
                      ),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: SpButton(
                  text: 'Lanjutkan ke Konfirmasi',
                  onPressed: _amountController.text.trim().isEmpty
                      ? null
                      : _proceed,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final double amount;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
