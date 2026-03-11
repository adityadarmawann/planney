import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/thousand_separator_formatter.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_snackbar.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  double _selectedAmount = 0;
  final _customController = TextEditingController();
  bool _useCustom = false;
  String? _selectedSource;

  final List<double> _presetAmounts = [
    5000, 25000, 50000, 100000, 250000, 1000000,
  ];

  final List<String> _topupSources = [
    'Indomaret',
    'Alfamart',
    'VA BNI',
    'VA Mandiri',
    'VA BCA',
    'E-wallet Dana',
    'E-wallet GoPay',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double get _finalAmount => _useCustom
      ? CurrencyFormatter.parse(_customController.text)
      : _selectedAmount;

  Future<void> _topUp() async {
    if (_finalAmount <= 0) {
      showSpSnackbar(context, 'Pilih atau masukkan nominal top up', isError: true);
      return;
    }

    if (_selectedSource == null || _selectedSource!.isEmpty) {
      showSpSnackbar(context, 'Pilih sumber top up terlebih dahulu', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();
    final userId = authProvider.currentUser?.id;
    final walletId = walletProvider.wallet?.id;

    if (userId == null || walletId == null) return;

    // Create transaction record (which also updates wallet balance)
    final txSuccess = await txProvider.topUp(
      userId: userId,
      walletId: walletId,
      amount: _finalAmount,
      note: 'Top Up via $_selectedSource',
    );

    if (!mounted) return;

    if (txSuccess) {
      // Refresh wallet balance in provider
      await walletProvider.loadWallet(userId);
      if (!mounted) return;

      final transaction = txProvider.lastTransaction;
      if (transaction != null) {
        // Navigate to success screen with transaction details
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.topupSuccess,
          (route) => route.settings.name == AppRoutes.wallet,
          arguments: transaction,
        );
      } else {
        showSpSnackbar(
          context,
          'Top up ${CurrencyFormatter.format(_finalAmount)} berhasil!',
          isSuccess: true,
        );
        Navigator.pop(context);
      }
    } else {
      showSpSnackbar(
        context,
        txProvider.errorMessage ?? 'Top up gagal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<WalletProvider>().isLoading;
    final balance = context.watch<WalletProvider>().balance;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.topupWallet)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Saat Ini',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        CurrencyFormatter.format(balance),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Nominal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected = !_useCustom && _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                      _useCustom = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                          'Rp ${CurrencyFormatter.formatAsPlainText(amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Atau masukkan nominal lain',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandSeparatorFormatter()],
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
                  borderSide: BorderSide(
                    color: _useCustom ? AppColors.primary : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _useCustom = v.isNotEmpty;
                  _selectedAmount = 0;
                });
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Pilih Sumber Top Up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSource,
              decoration: InputDecoration(
                hintText: 'Pilih sumber top up',
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
              items: _topupSources.map((source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(source),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSource = value;
                  });
                }
              },
              icon: const Icon(Icons.expand_more, color: AppColors.primary),
              dropdownColor: AppColors.backgroundSecondary,
              isExpanded: true,
            ),
            const SizedBox(height: 32),
            SpButton(
              text: _finalAmount > 0
                  ? 'Top Up ${CurrencyFormatter.format(_finalAmount)}'
                  : AppStrings.processTopup,
              onPressed: _topUp,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
