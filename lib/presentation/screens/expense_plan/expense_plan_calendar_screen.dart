import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_plan_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/expense_plan_model.dart';
import 'expense_plan_create_screen.dart';
import '../../widgets/common/sp_button.dart';

class ExpensePlanCalendarScreen extends StatefulWidget {
  const ExpensePlanCalendarScreen({super.key});

  @override
  State<ExpensePlanCalendarScreen> createState() =>
      _ExpensePlanCalendarScreenState();
}

class _ExpensePlanCalendarScreenState extends State<ExpensePlanCalendarScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExpensePlans();
  }

  void _loadExpensePlans() {
    final authProvider = context.read<AuthProvider>();
    final expensePlanProvider = context.read<ExpensePlanProvider>();

    if (authProvider.currentUser != null) {
      expensePlanProvider.loadExpensePlansForMonth(
        authProvider.currentUser!.id,
        _selectedDate.year,
        _selectedDate.month,
      );
    }
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    _loadExpensePlans();
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    _loadExpensePlans();
  }

  Future<void> _deleteExpensePlan(
    ExpensePlanProvider provider,
    String planId,
    String planTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Rencana'),
        content: Text('Hapus rencana "$planTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await provider.deleteExpensePlan(planId);
    if (!mounted) return;

    _loadExpensePlans();

    final message = success
      ? 'Rencana berhasil dihapus'
      : (provider.errorMessage ?? 'Gagal menghapus rencana');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _openEditExpensePlan(ExpensePlan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpensePlanCreateScreen(plan: plan),
      ),
    );

    if (!mounted) return;
    _loadExpensePlans();
  }

  String _formatReminderLabel(ExpensePlan plan) {
    if (plan.reminderType == null) return 'Tanpa pengingat';
    switch (plan.reminderType) {
      case ReminderType.h1:
        return '1 hari sebelumnya';
      case ReminderType.h3:
        return '3 jam sebelumnya';
      case ReminderType.custom:
        final minutes = plan.effectiveCustomReminderMinutes;
        if (minutes == null || minutes <= 0) return 'Custom';
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')} sebelumnya';
      default:
        return plan.reminderType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensePlanProvider = context.watch<ExpensePlanProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Rencana Pengeluaran'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Header dengan month navigation
              _buildCalendarHeader(),
              const SizedBox(height: 24),

              // Calendar Grid
              _buildCalendarGrid(expensePlanProvider),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCards(expensePlanProvider, authProvider),
              const SizedBox(height: 32),

              // Expense plans untuk tanggal yang dipilih
              _buildSelectedDateExpensePlans(expensePlanProvider),
              const SizedBox(height: 32),

              // Add Button
              SpButton(
                text: 'Tambah Rencana Pengeluaran',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpensePlanCreateScreen(
                        initialDate: _selectedDate,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  _loadExpensePlans();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: Icon(Icons.chevron_left),
          color: AppColors.secondary,
        ),
        Text(
          DateFormatter.formatMonthYear(_selectedDate),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: Icon(Icons.chevron_right),
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ExpensePlanProvider provider) {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Convert Dart's weekday (1=Mon, 7=Sun) to calendar position (0=Sun, 1=Mon, ..., 6=Sat)
    final startingWeekdayIndex = firstDay.weekday % 7;

    final datesWithPlans = provider.getDatesWithPlans();

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
              .map((day) => Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Calendar days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            final day = index - startingWeekdayIndex + 1;

            if (day < 1 || day > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(_selectedDate.year, _selectedDate.month, day);
            final isSelected = day == _selectedDate.day;
            final hasPlans = datesWithPlans.any((d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day);
            final isToday = DateTime.now().day == day &&
                DateTime.now().month == _selectedDate.month &&
                DateTime.now().year == _selectedDate.year;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.secondary
                      : hasPlans
                          ? AppColors.secondaryLight.withValues(alpha: 0.25)
                          : Colors.transparent,
                  border: isToday
                      ? Border.all(color: AppColors.secondary, width: 2)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (hasPlans && !isSelected)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    ExpensePlanProvider provider,
    AuthProvider authProvider,
  ) {
    return FutureBuilder<double>(
      future: provider.getTotalForMonth(
        authProvider.currentUser!.id,
        _selectedDate.year,
        _selectedDate.month,
      ),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ${DateFormatter.formatMonthYear(_selectedDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(total),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDateExpensePlans(ExpensePlanProvider provider) {
    final plansForDate = provider.getExpensePlansForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rencana Pengeluaran - ${DateFormatter.formatDate(_selectedDate)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (plansForDate.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada rencana pengeluaran',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plansForDate.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = plansForDate[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: plan.isCompleted
                      ? AppColors.textHint.withValues(alpha: 0.05)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: plan.isCompleted
                        ? AppColors.textHint.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox untuk mark as completed
                        InkWell(
                          onTap: () async {
                            final success = await provider.toggleCompleted(
                              plan.id,
                              plan.isCompleted,
                            );
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? (plan.isCompleted
                                          ? 'Rencana ditandai belum selesai'
                                          : 'Rencana ditandai selesai')
                                      : (provider.errorMessage ??
                                          'Gagal mengubah status rencana'),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            plan.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: plan.isCompleted
                                ? AppColors.success
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        decoration: plan.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(plan.amount),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                          decoration: plan.isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          decorationColor:
                                              AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      InkWell(
                                        onTap: () => _openEditExpensePlan(plan),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _deleteExpensePlan(
                                          provider,
                                          plan.id,
                                          plan.title,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  decoration: plan.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Sumber: ${plan.paymentSource}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jam: ${plan.plannedTime}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pengingat: ${_formatReminderLabel(plan)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                              if (plan.notes != null &&
                                  plan.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  plan.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

