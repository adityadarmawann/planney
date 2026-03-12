import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final subtitle = switch (transaction.type) {
      TransactionType.qrisPayment || TransactionType.qrisPaylater =>
        transaction.merchantName == null
            ? DateFormatter.formatRelative(transaction.createdAt)
            : '${transaction.merchantName} • ${DateFormatter.formatRelative(transaction.createdAt)}',
      _ => DateFormatter.formatRelative(transaction.createdAt),
    };

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_getIcon(), color: _getColor(), size: 22),
      ),
      title: Text(
        transaction.typeLabel,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isCredit ? AppColors.income : AppColors.expense,
            ),
          ),
          Text(
            transaction.refCode,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.topup:
        return Icons.add_circle;
      case TransactionType.transferIn:
        return Icons.arrow_downward_rounded;
      case TransactionType.transferOut:
        return Icons.arrow_upward_rounded;
      case TransactionType.bankTransfer:
        return Icons.account_balance;
      case TransactionType.qrisPayment:
        return Icons.qr_code_scanner_rounded;
      case TransactionType.qrisPaylater:
        return Icons.qr_code_2_rounded;
      case TransactionType.paylaterDisbursement:
        return Icons.credit_score;
      case TransactionType.paylaterPayment:
        return Icons.payment;
      case TransactionType.withdrawal:
        return Icons.money_off;
    }
  }

  Color _getColor() {
    switch (transaction.type) {
      case TransactionType.topup:
      case TransactionType.transferIn:
      case TransactionType.paylaterDisbursement:
        return AppColors.income;
      case TransactionType.transferOut:
      case TransactionType.bankTransfer:
      case TransactionType.qrisPayment:
      case TransactionType.qrisPaylater:
      case TransactionType.paylaterPayment:
      case TransactionType.withdrawal:
        return AppColors.expense;
    }
  }
}
