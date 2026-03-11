import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/paylater_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../data/models/paylater_bill_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/common/sp_card.dart';
import '../../widgets/common/sp_loading.dart';
import '../../widgets/common/sp_snackbar.dart';

class PaylaterBillScreen extends StatefulWidget {
  const PaylaterBillScreen({super.key});

  @override
  State<PaylaterBillScreen> createState() => _PaylaterBillScreenState();
}

class _PaylaterBillScreenState extends State<PaylaterBillScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<PaylaterProvider>().loadBills(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaylaterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Paylater'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading && provider.bills.isEmpty
          ? const SpLoading()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: provider.bills.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 56, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada tagihan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: provider.bills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bill = provider.bills[index];
                        return _BillItem(
                          bill: bill,
                          onPay: bill.status == BillStatus.active
                              ? () => _payBill(bill)
                              : null,
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _payBill(PaylaterBillModel bill) async {
    final walletProvider = context.read<WalletProvider>();
    final paylaterProvider = context.read<PaylaterProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final walletId = walletProvider.wallet?.id;

    if (userId == null || walletId == null) return;

    if (walletProvider.balance < bill.totalDue) {
      showSpSnackbar(context, 'Saldo tidak cukup', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bayar Tagihan'),
        content: Text(
          'Bayar ${CurrencyFormatter.format(bill.totalDue)} dari saldo wallet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await paylaterProvider.payBill(
      billId: bill.id,
      userId: userId,
      walletId: walletId,
    );

    if (!mounted) return;

    if (success) {
      await walletProvider.loadWallet(userId);
      // ignore: use_build_context_synchronously
      showSpSnackbar(context, 'Tagihan berhasil dibayar!', isSuccess: true);
    } else {
      showSpSnackbar(
        context,
        paylaterProvider.errorMessage ?? 'Pembayaran gagal',
        isError: true,
      );
    }
  }
}

class _BillItem extends StatelessWidget {
  final PaylaterBillModel bill;
  final VoidCallback? onPay;

  const _BillItem({required this.bill, this.onPay});

  @override
  Widget build(BuildContext context) {
    final statusColor = bill.status == BillStatus.paid
        ? AppColors.success
        : bill.effectiveStatus == BillStatus.overdue
            ? AppColors.error
            : AppColors.warning;
    final statusText = bill.status == BillStatus.paid
        ? 'Lunas'
        : bill.effectiveStatus == BillStatus.overdue
            ? 'Telat'
            : 'Aktif';

    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(bill.totalDue),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tenor: ${bill.tenorMonths} bulan | Pokok: ${CurrencyFormatter.format(bill.principalAmount)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jatuh Tempo: ${DateFormatter.formatDate(bill.dueDate)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              if (bill.status == BillStatus.paid && bill.paidAt != null)
                Text(
                  'Dibayar: ${DateFormatter.formatDate(bill.paidAt!)}',
                  style: const TextStyle(
                      color: AppColors.success, fontSize: 11),
                ),
            ],
          ),
          if (onPay != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
                child: const Text('Bayar Sekarang'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
