import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class WalletSummaryChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const WalletSummaryChart({
    super.key,
    required this.transactions,
  });

  /// Calculate income from top-ups
  double get topupAmount {
    return transactions
        .where((t) =>
            t.type == TransactionType.topup && t.status == TransactionStatus.success)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Calculate expenses (transfers and bank transfers)
  double get expenseAmount {
    return transactions
        .where((t) =>
            (t.type == TransactionType.transferOut ||
                t.type == TransactionType.bankTransfer) &&
            t.status == TransactionStatus.success)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Calculate pay later transactions (disbursement + payment)
  double get paylaterAmount {
    return transactions
        .where((t) =>
            (t.type == TransactionType.paylaterDisbursement ||
                t.type == TransactionType.paylaterPayment) &&
            t.status == TransactionStatus.success)
        .fold(0, (sum, t) => sum + t.amount);
  }

  String _getTitleLabel(double value) {
    switch (value.toInt()) {
      case 0:
        return 'Top Up';
      case 1:
        return 'Pengeluaran';
      case 2:
        return 'Pay Later';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (topupAmount == 0 && expenseAmount == 0 && paylaterAmount == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada data transaksi',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar chart
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                groupsSpace: 48,
                maxY: null,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = rod.toY.toInt().toDouble();
                      return BarTooltipItem(
                        CurrencyFormatter.format(amount),
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getTitleLabel(value),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      reservedSize: 42,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: topupAmount,
                        color: AppColors.income,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: expenseAmount,
                        color: AppColors.expense,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: paylaterAmount,
                        color: AppColors.secondary,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend and values
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              _SummaryItem(
                color: AppColors.income,
                label: 'Top Up',
                value: topupAmount,
              ),
              const SizedBox(height: 12),
              _SummaryItem(
                color: AppColors.expense,
                label: 'Pengeluaran',
                value: expenseAmount,
              ),
              const SizedBox(height: 12),
              _SummaryItem(
                color: AppColors.secondary,
                label: 'Pay Later',
                value: paylaterAmount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _SummaryItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
