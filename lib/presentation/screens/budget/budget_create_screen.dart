import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_text_field.dart';
import '../../widgets/common/sp_snackbar.dart';

class BudgetCreateScreen extends StatefulWidget {
  const BudgetCreateScreen({super.key});

  @override
  State<BudgetCreateScreen> createState() => _BudgetCreateScreenState();
}

class _BudgetCreateScreenState extends State<BudgetCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  PeriodType _periodType = PeriodType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate =
      DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setPeriod(PeriodType type) {
    setState(() {
      _periodType = type;
      _startDate = DateTime.now();
      switch (type) {
        case PeriodType.weekly:
          _endDate = _startDate.add(const Duration(days: 7));
          break;
        case PeriodType.monthly:
          _endDate = DateTime(
              _startDate.year, _startDate.month + 1, _startDate.day);
          break;
        case PeriodType.custom:
          break;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      showSpSnackbar(context, 'Tanggal selesai harus setelah tanggal mulai',
          isError: true);
      return;
    }

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final budget = await context.read<BudgetProvider>().createBudget(
          userId: userId,
          name: _nameController.text.trim(),
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
        );

    if (!mounted) return;

    if (budget != null) {
      showSpSnackbar(context, 'Anggaran berhasil dibuat!', isSuccess: true);
      Navigator.pop(context);
    } else {
      showSpSnackbar(
        context,
        context.read<BudgetProvider>().errorMessage ?? 'Gagal membuat anggaran',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BudgetProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.createBudget),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpTextField(
                label: AppStrings.budgetName,
                hint: 'Contoh: Anggaran Oktober 2024',
                controller: _nameController,
                validator: (v) =>
                    Validators.validateRequired(v, 'Nama anggaran'),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.periodType,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PeriodChip(
                    label: AppStrings.weekly,
                    isSelected: _periodType == PeriodType.weekly,
                    onTap: () => _setPeriod(PeriodType.weekly),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: AppStrings.monthly,
                    isSelected: _periodType == PeriodType.monthly,
                    onTap: () => _setPeriod(PeriodType.monthly),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: AppStrings.custom,
                    isSelected: _periodType == PeriodType.custom,
                    onTap: () => _setPeriod(PeriodType.custom),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DatePicker(
                      label: AppStrings.startDate,
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePicker(
                      label: AppStrings.endDate,
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SpButton(
                text: AppStrings.createBudget,
                onPressed: _create,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePicker({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
