import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/expense_plan_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/common/sp_card.dart';
import '../../widgets/common/sp_loading.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final budgetProvider = context.read<BudgetProvider>();
    final expensePlanProvider = context.read<ExpensePlanProvider>();
    final now = DateTime.now();
    await Future.wait([
      budgetProvider.loadBudgets(userId),
      budgetProvider.loadCategories(userId: userId),
      expensePlanProvider.loadExpensePlansForMonth(userId, now.year, now.month),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final expensePlanProvider = context.watch<ExpensePlanProvider>();
    
    // Filter: hanya tampilkan yang belum completed di list utama
    final monthlyPlans = expensePlanProvider.expensePlans
        .where((plan) => !plan.isCompleted)
        .toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plan'),
        actions: [
          Consumer<ExpensePlanProvider>(
            builder: (context, expensePlanProvider, _) {
                // Badge count: hanya hitung yang belum completed
                final planCount = expensePlanProvider.expensePlans
                  .where((plan) => !plan.isCompleted)
                  .length;
              return IconButton(
                tooltip: 'Rencana Pengeluaran',
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.expensePlanCalendar,
                ).then((_) => _loadData()),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.calendar_month_rounded),
                    if (planCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            planCount > 99 ? '99+' : '$planCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading &&
                provider.budgets.isEmpty &&
                monthlyPlans.isEmpty
            ? const SpLoading()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (monthlyPlans.isNotEmpty) ...[
                    const Text(
                      'Rencana Pengeluaran Bulan Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...monthlyPlans.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ExpensePlanMiniCard(
                          id: plan.id,
                          title: plan.title,
                          category: plan.category,
                          paymentSource: plan.paymentSource,
                          plannedDate: plan.plannedDate,
                          amount: plan.amount,
                          isCompleted: plan.isCompleted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  // Ringkasan Saku Anggaran
                  if (provider.budgets.isNotEmpty) ...[  
                    const Text(
                      'Ringkasan Saku Anggaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        // Summary should reflect all budget pockets, not a single active one.
                        final totalIncome = provider.budgets.fold<double>(
                          0,
                          (sum, budget) => sum + budget.totalIncome,
                        );
                        final totalExpense = provider.budgets.fold<double>(
                          0,
                          (sum, budget) => sum + budget.totalExpense,
                        );
                        
                        return SpCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 50,
                                    borderData: FlBorderData(show: false),
                                    sections: [
                                      PieChartSectionData(
                                        value: totalIncome > 0 ? totalIncome : 1,
                                        color: AppColors.income,
                                        title: '',
                                        radius: 40,
                                      ),
                                      PieChartSectionData(
                                        value: totalExpense > 0 ? totalExpense : 1,
                                        color: AppColors.expense,
                                        title: '',
                                        radius: 40,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _SummaryRow(
                                color: AppColors.income,
                                label: 'Total Pemasukan',
                                value: CurrencyFormatter.format(totalIncome),
                              ),
                              const SizedBox(height: 12),
                              _SummaryRow(
                                color: AppColors.expense,
                                label: 'Total Pengeluaran',
                                value: CurrencyFormatter.format(totalExpense),
                              ),
                              const Divider(height: 24),
                              _SummaryRow(
                                color: AppColors.primary,
                                label: 'Sisa Saldo',
                                value: CurrencyFormatter.format(totalIncome - totalExpense),
                                isTotal: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Saku Anggaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.budgets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pie_chart_outline,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada anggaran',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...provider.budgets.map(
                      (budget) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BudgetCard(
                          budget: budget,
                          onTap: () {
                            provider.selectBudget(budget);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.budgetDetail,
                              arguments: budget,
                            ).then((_) => _loadData());
                          },
                          onDelete: () => _deleteBudget(budget),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.budgetCreate)
                .then((_) => _loadData()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Anggaran'),
        content: Text('Hapus anggaran "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BudgetProvider>().deleteBudget(budget.id);
    }
  }
}

class _ExpensePlanMiniCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String paymentSource;
  final DateTime plannedDate;
  final double amount;
  final bool isCompleted;

  const _ExpensePlanMiniCard({
    required this.id,
    required this.title,
    required this.category,
    required this.paymentSource,
    required this.plannedDate,
    required this.amount,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.schedule_rounded,
              color: isCompleted ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormatter.formatDate(plannedDate)} • $category',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sumber: $paymentSource',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = budget.percentageUsed;
    final progressColor = percent >= 90
        ? AppColors.error
        : percent >= 70
            ? AppColors.warning
            : AppColors.success;

    return SpCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${budget.periodTypeLabel} • ${DateFormatter.formatDate(budget.startDate)} - ${DateFormatter.formatDate(budget.endDate)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pemasukan',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                    Text(
                      CurrencyFormatter.format(budget.totalIncome),
                      style: const TextStyle(
                        color: AppColors.income,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengeluaran',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                    Text(
                      CurrencyFormatter.format(budget.totalExpense),
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sisa',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                    Text(
                      CurrencyFormatter.format(budget.remaining),
                      style: TextStyle(
                        color: budget.remaining >= 0
                            ? AppColors.primary
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percent.toStringAsFixed(0)}% terpakai',
            style: TextStyle(
              color: progressColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.color,
    required this.label,
    required this.value,
    this.isTotal = false,
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
