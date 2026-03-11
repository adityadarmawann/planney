import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/common/sp_card.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx =
        ModalRoute.of(context)!.settings.arguments as TransactionModel;
    final isCredit = tx.isCredit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isCredit
                    ? LinearGradient(
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.expense,
                          AppColors.expense.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    isCredit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tx.typeLabel,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatDateTime(tx.createdAt),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Kode Referensi',
                    value: tx.refCode,
                    isCode: true,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Jenis Transaksi',
                    value: tx.typeLabel,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Status',
                    value: _statusLabel(tx.status),
                    valueColor: tx.status == TransactionStatus.success
                        ? AppColors.success
                        : tx.status == TransactionStatus.failed
                            ? AppColors.error
                            : AppColors.warning,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Jumlah',
                    value: CurrencyFormatter.format(tx.amount),
                  ),
                  if (tx.fee > 0) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Biaya Admin',
                      value: CurrencyFormatter.format(tx.fee),
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Total',
                      value: CurrencyFormatter.format(tx.amount + tx.fee),
                      isBold: true,
                    ),
                  ],
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _DetailRow(label: 'Catatan', value: tx.note!),
                  ],
                  // Metadata
                  if (tx.metadata != null) ...[
                    const Divider(height: 20),
                    ..._buildMetadata(tx.metadata!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Berhasil';
      case TransactionStatus.pending:
        return 'Menunggu';
      case TransactionStatus.failed:
        return 'Gagal';
      case TransactionStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  List<Widget> _buildMetadata(Map<String, dynamic> metadata) {
    final widgets = <Widget>[];
    if (metadata['bank_name'] != null) {
      widgets.add(_DetailRow(label: 'Bank', value: metadata['bank_name']));
      widgets.add(const Divider(height: 20));
    }
    if (metadata['account_number'] != null) {
      widgets.add(_DetailRow(
          label: 'No. Rekening', value: metadata['account_number']));
      widgets.add(const Divider(height: 20));
    }
    if (metadata['merchant_name'] != null) {
      widgets.add(_DetailRow(
          label: 'Merchant', value: metadata['merchant_name']));
    }
    return widgets;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isCode;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(width: 16),
        isCode
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              )
            : Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontSize: isBold ? 15 : 14,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
      ],
    );
  }
}
