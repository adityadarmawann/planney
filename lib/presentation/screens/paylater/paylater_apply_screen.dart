import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/paylater_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_snackbar.dart';

class PaylaterApplyScreen extends StatefulWidget {
  const PaylaterApplyScreen({super.key});

  @override
  State<PaylaterApplyScreen> createState() => _PaylaterApplyScreenState();
}

class _PaylaterApplyScreenState extends State<PaylaterApplyScreen> {
  double _amount = 0;
  int _tenor = 3;
  final _amountController = TextEditingController();

  final List<int> _tenors = [1, 2, 3, 6, 9, 12];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _interestAmount {
    final account = context.read<PaylaterProvider>().account;
    final rate = account?.interestRate ?? 2.5;
    return _amount * (rate / 100) * _tenor;
  }

  double get _totalDue => _amount + _interestAmount;

  Future<void> _disburse() async {
    _amount = CurrencyFormatter.parse(_amountController.text);

    if (_amount <= 0) {
      showSpSnackbar(context, 'Masukkan jumlah pencairan', isError: true);
      return;
    }

    final paylaterProvider = context.read<PaylaterProvider>();
    final account = paylaterProvider.account;
    if (account == null) return;

    if (_amount > account.remainingLimit) {
      showSpSnackbar(context, 'Jumlah melebihi sisa limit', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final userId = authProvider.currentUser?.id;
    final walletId = walletProvider.wallet?.id;
    if (userId == null || walletId == null) return;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pencairan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Cairkan ${CurrencyFormatter.format(_amount)} dengan tenor $_tenor bulan?'),
            const SizedBox(height: 8),
            Text(
              'Total tagihan: ${CurrencyFormatter.format(_totalDue)}',
              style: const TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cairkan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await paylaterProvider.disbursePaylater(
      userId: userId,
      walletId: walletId,
      amount: _amount,
      tenorMonths: _tenor,
    );

    if (!mounted) return;

    if (success) {
      await walletProvider.loadWallet(userId);
      showSpSnackbar(
        // ignore: use_build_context_synchronously
        context,
        'Dana ${CurrencyFormatter.format(_amount)} berhasil dicairkan!',
        isSuccess: true,
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } else {
      // ignore: use_build_context_synchronously
      showSpSnackbar(
        context,
        paylaterProvider.errorMessage ?? 'Pencairan gagal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaylaterProvider>();
    final account = provider.account;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cairkan Dana Paylater'),
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
            // Remaining limit info
            if (account != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_score, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sisa Limit',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(account.remainingLimit),
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
            const Text('Jumlah Pencairan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                setState(() {
                  _amount = CurrencyFormatter.parse(v);
                });
              },
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
            const SizedBox(height: 20),
            const Text('Pilih Tenor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tenors.map((t) {
                final isSelected = _tenor == t;
                return GestureDetector(
                  onTap: () => setState(() => _tenor = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
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
                    child: Text(
                      '$t Bulan',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_amount > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        label: 'Pokok',
                        value: CurrencyFormatter.format(_amount)),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Bunga (${account?.interestRate ?? 2.5}%/bulan × $_tenor bln)',
                      value: CurrencyFormatter.format(_interestAmount),
                      valueColor: AppColors.warning,
                    ),
                    const Divider(height: 16),
                    _SummaryRow(
                      label: 'Total Tagihan',
                      value: CurrencyFormatter.format(_totalDue),
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SpButton(
              text: 'Cairkan Dana',
              onPressed: _disburse,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 13,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
