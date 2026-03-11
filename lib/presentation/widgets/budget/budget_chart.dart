import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class BudgetChart extends StatelessWidget {
  final double income;
  final double expense;

  const BudgetChart({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    if (income == 0 && expense == 0) {
      return const Center(
        child: Text(
          'Belum ada data anggaran',
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: PieChart(
            PieChartData(
              sections: [
                if (income > 0)
                  PieChartSectionData(
                    value: income,
                    color: AppColors.income,
                    title: '',
                    radius: 45,
                  ),
                if (expense > 0)
                  PieChartSectionData(
                    value: expense,
                    color: AppColors.expense,
                    title: '',
                    radius: 45,
                  ),
                if (income > expense)
                  PieChartSectionData(
                    value: income - expense,
                    color: AppColors.primaryLightest,
                    title: '',
                    radius: 45,
                  ),
              ],
              centerSpaceRadius: 25,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(
              color: AppColors.income,
              label: 'Pemasukan',
              value: income,
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.expense,
              label: 'Pengeluaran',
              value: expense,
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.primaryLightest,
              label: 'Sisa',
              value: (income - expense).clamp(0, double.infinity),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
