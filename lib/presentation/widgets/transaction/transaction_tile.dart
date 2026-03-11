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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        DateFormatter.formatRelative(transaction.createdAt),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
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
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textHint,
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
      case TransactionType.paylaterPayment:
      case TransactionType.withdrawal:
        return AppColors.expense;
    }
  }
}
