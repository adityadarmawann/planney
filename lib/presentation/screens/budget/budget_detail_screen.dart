import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/budget_item_model.dart';
import '../../../data/models/category_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/common/sp_card.dart';
import '../../widgets/common/sp_loading.dart';
import '../../widgets/common/sp_snackbar.dart';
import '../../widgets/budget/budget_chart.dart';

class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({super.key});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late BudgetModel _budget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _budget = ModalRoute.of(context)!.settings.arguments as BudgetModel;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final provider = context.read<BudgetProvider>();
    await Future.wait([
      provider.loadBudgetItems(_budget.id),
      provider.loadCategories(userId: userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final budget = provider.selectedBudget ?? _budget;

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddItemSheet(context),
          ),
        ],
      ),
      body: provider.isLoading && provider.budgetItems.isEmpty
          ? const SpLoading()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    SpCard(
                      color: AppColors.secondaryLight.withValues(alpha: 0.2),
                      hasBorder: false,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _SummaryItem(
                                label: 'Pemasukan',
                                value:
                                    CurrencyFormatter.format(budget.totalIncome),
                                color: AppColors.income,
                              ),
                              _SummaryItem(
                                label: 'Pengeluaran',
                                value: CurrencyFormatter.format(
                                    budget.totalExpense),
                                color: AppColors.expense,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sisa Anggaran',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                CurrencyFormatter.format(budget.remaining),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: budget.remaining >= 0
                                      ? AppColors.secondary
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: budget.percentageUsed / 100,
                              backgroundColor:
                                  AppColors.secondary.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budget.percentageUsed >= 90
                                    ? AppColors.error
                                    : budget.percentageUsed >= 70
                                        ? AppColors.warning
                                        : AppColors.success,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${budget.percentageUsed.toStringAsFixed(0)}% dari anggaran terpakai',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Chart
                    SpCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grafik Anggaran',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          BudgetChart(
                            income: budget.totalIncome,
                            expense: budget.totalExpense,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Items list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daftar Item',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: () => _showAddItemSheet(context),
                          icon: Icon(Icons.add, size: 16),
                          label: Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (provider.budgetItems.isEmpty)
                      SpCard(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Belum ada item anggaran. Tap + untuk menambah.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    else
                      ...provider.budgetItems.map(
                        (item) => _ItemCard(
                          item: item,
                          categories: provider.categories,
                          onDelete: () =>
                              _deleteItem(item),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddItemSheet(
        budgetId: _budget.id,
        categories: context.read<BudgetProvider>().categories,
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _deleteItem(BudgetItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Item'),
        content: Text('Hapus item anggaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BudgetProvider>().deleteBudgetItem(item.id, _budget.id);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final BudgetItemModel item;
  final List<CategoryModel> categories;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.categories,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories
        .where((c) => c.id == item.categoryId)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.type == ItemType.income
                ? AppColors.successLight
                : AppColors.errorLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category?.icon ??
                  (item.type == ItemType.income ? '💰' : '💸'),
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          item.description ??
              category?.name ??
              (item.type == ItemType.income ? 'Pemasukan' : 'Pengeluaran'),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(DateFormatter.formatDate(item.date),
            style: TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.type == ItemType.income ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
              style: TextStyle(
                color: item.type == ItemType.income
                    ? AppColors.income
                    : AppColors.expense,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final String budgetId;
  final List<CategoryModel> categories;

  const _AddItemSheet({
    required this.budgetId,
    required this.categories,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  ItemType _type = ItemType.expense;
  CategoryModel? _selectedCategory;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filteredCategories => widget.categories
      .where((c) =>
          c.type == (_type == ItemType.income
              ? CategoryType.income
              : CategoryType.expense))
      .toList();

  Future<void> _save() async {
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      showSpSnackbar(context, 'Masukkan jumlah yang valid', isError: true);
      return;
    }

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final success = await context.read<BudgetProvider>().addBudgetItem(
          budgetId: widget.budgetId,
          userId: userId,
          categoryId: _selectedCategory?.id,
          type: _type,
          amount: amount,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _date,
        );

    if (!mounted) return;

    if (success) {
      showSpSnackbar(context, 'Item berhasil ditambahkan', isSuccess: true);
      Navigator.pop(context);
    } else {
      showSpSnackbar(
        context,
        context.read<BudgetProvider>().errorMessage ?? 'Gagal menambah item',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah Item Anggaran',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Type toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _type = ItemType.income),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _type == ItemType.income
                          ? AppColors.income
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+ Pemasukan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _type == ItemType.income
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _type = ItemType.expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _type == ItemType.expense
                          ? AppColors.expense
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '- Pengeluaran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _type == ItemType.expense
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category
          DropdownButtonFormField<CategoryModel>(
            initialValue: _selectedCategory,
            hint: Text('Pilih Kategori'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.secondary)),
              filled: true,
            ),
            items: _filteredCategories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text('${cat.icon} ${cat.name}'),
              );
            }).toList(),
            onChanged: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixText: 'Rp ',
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.secondary)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Deskripsi (opsional)',
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.secondary)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text('Simpan'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
