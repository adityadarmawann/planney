import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

enum PaymentMethod { wallet, paylater }

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final int selectedTenor;
  final double amount;
  final double walletBalance;
  final double paylaterLimit;
  final double interestRate;
  final Function(PaymentMethod) onMethodChanged;
  final Function(int) onTenorChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.selectedTenor,
    required this.amount,
    required this.walletBalance,
    required this.paylaterLimit,
    required this.interestRate,
    required this.onMethodChanged,
    required this.onTenorChanged,
  });

  double get interestAmount => amount * (interestRate / 100) * selectedTenor;
  double get totalDue => amount + interestAmount;
  bool get canUseWallet => amount <= walletBalance;
  bool get canUsePaylater => amount <= paylaterLimit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        // Wallet Option
        _PaymentMethodCard(
          icon: Icons.account_balance_wallet,
          title: 'Student Wallet',
          subtitle: 'Saldo: ${CurrencyFormatter.format(walletBalance)}',
          isSelected: selectedMethod == PaymentMethod.wallet,
          isEnabled: canUseWallet,
          onTap: canUseWallet ? () => onMethodChanged(PaymentMethod.wallet) : null,
          warningText: !canUseWallet ? 'Saldo tidak cukup' : null,
        ),
        const SizedBox(height: 12),
        // PayLater Option
        _PaymentMethodCard(
          icon: Icons.credit_card,
          title: 'PayLater',
          subtitle: 'Limit: ${CurrencyFormatter.format(paylaterLimit)}',
          isSelected: selectedMethod == PaymentMethod.paylater,
          isEnabled: canUsePaylater,
          onTap: canUsePaylater
              ? () => onMethodChanged(PaymentMethod.paylater)
              : null,
          warningText: !canUsePaylater ? 'Limit tidak cukup' : null,
        ),
        // Tenor Selector (only shown when PayLater selected)
        if (selectedMethod == PaymentMethod.paylater) ...[
          const SizedBox(height: 20),
          Text(
            'Pilih Tenor Cicilan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedTenor,
                        decoration: const InputDecoration(
                          labelText: 'Tenor',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 Bulan')),
                          DropdownMenuItem(value: 3, child: Text('3 Bulan')),
                          DropdownMenuItem(value: 6, child: Text('6 Bulan')),
                          DropdownMenuItem(value: 12, child: Text('12 Bulan')),
                        ],
                        onChanged: (value) {
                          if (value != null) onTenorChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Jumlah Pembayaran',
                  value: CurrencyFormatter.format(amount),
                ),
                const SizedBox(height: 6),
                _DetailRow(
                  label: 'Bunga ($interestRate% × $selectedTenor bln)',
                  value: CurrencyFormatter.format(interestAmount),
                  valueColor: AppColors.warning,
                ),
                const Divider(height: 16),
                _DetailRow(
                  label: 'Total Tagihan',
                  value: CurrencyFormatter.format(totalDue),
                  isBold: true,
                  valueColor: AppColors.error,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bayar sebelum ${_getDueDate()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getDueDate() {
    final dueDate = DateTime.now().add(Duration(days: selectedTenor * 30));
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final String? warningText;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isEnabled,
    this.onTap,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !isEnabled
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : isSelected
                  ? AppColors.secondaryLight.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !isEnabled
                ? AppColors.border
                : isSelected
                    ? AppColors.secondary
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: !isEnabled
                    ? AppColors.textHint.withValues(alpha: 0.1)
                    : isSelected
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: !isEnabled
                    ? AppColors.textHint
                    : isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                size: 22,
              ),
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
                      color: !isEnabled ? AppColors.textHint : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    warningText ?? subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: warningText != null
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight:
                          warningText != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.secondary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
