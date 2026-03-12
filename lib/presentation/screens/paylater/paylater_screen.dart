import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/paylater_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../data/models/paylater_account_model.dart';
import '../../../data/models/paylater_bill_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/common/sp_card.dart';
import '../../widgets/common/sp_loading.dart';
import '../../widgets/common/sp_snackbar.dart';

class PaylaterScreen extends StatefulWidget {
  const PaylaterScreen({super.key});

  @override
  State<PaylaterScreen> createState() => _PaylaterScreenState();
}

class _PaylaterScreenState extends State<PaylaterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final provider = context.read<PaylaterProvider>();
    await Future.wait([
      provider.loadAccount(userId),
      provider.loadBills(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaylaterProvider>();

    if (provider.isLoading && provider.account == null) {
      return const Scaffold(body: SpLoading());
    }

    final account = provider.account;

    return Scaffold(
      appBar: AppBar(
        title: Text('PayLater'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account card
              if (account != null) _buildAccountCard(account),
              const SizedBox(height: 24),
              
              // Overdue Bills (prioritas tertinggi)
              if (provider.overdueBills.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tagihan Terlambat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.overdueBills.map(
                  (bill) => _BillCard(
                    bill: bill,
                    onPay: () => _payBill(context, bill),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Active Bills (belum jatuh tempo)
              Text(
                'Tagihan Aktif',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (provider.activeBills.isEmpty && provider.overdueBills.isEmpty)
                SpCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.success),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada tagihan aktif',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...provider.activeBills.map(
                  (bill) => _BillCard(
                    bill: bill,
                    onPay: () => _payBill(context, bill),
                  ),
                ),
              
              // Paid Bills (history)
              if (provider.paidBills.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Riwayat Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...provider.paidBills.take(5).map(
                  (bill) => _BillCard(
                    bill: bill,
                    onPay: null, // tidak bisa bayar lagi
                  ),
                ),
                if (provider.paidBills.length > 5) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.paylaterBill),
                    child: Text('Lihat Semua Riwayat'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(PaylaterAccountModel account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_score, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Akun Paylater',
                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LimitInfo(
                label: 'Total Limit',
                value: CurrencyFormatter.format(account.creditLimit),
              ),
              const SizedBox(width: 24),
              _LimitInfo(
                label: 'Sisa Limit',
                value: CurrencyFormatter.format(account.remainingLimit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: account.usedPercentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Terpakai ${account.usedPercentage.toStringAsFixed(0)}% | Bunga ${account.interestRate}%/bulan',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          
          // Limit Increase Progress Tracker
          if (!account.isMaxLimit) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Progress Kenaikan Limit',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
                      // Progress bar untuk 3 pembayaran
                      Row(
                        children: List.generate(3, (index) {
                          final isCompleted = index < account.onTimePaymentCount;
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCompleted 
                                  ? Colors.white 
                                  : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        account.onTimePaymentCount == 0
                          ? 'Bayar 3x tepat waktu untuk naik Rp 500rb'
                          : '${account.paymentsNeededForIncrease}x lagi bayar tepat waktu → Rp ${CurrencyFormatter.formatAsPlainText(account.creditLimit + 500000)}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total dibayar: ${account.totalPaidBills}x',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Text(
                  'Target max: Rp 10jt',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Limit Maksimal Tercapai! 🎉',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _payBill(BuildContext context, PaylaterBillModel bill) async {
    final walletProvider = context.read<WalletProvider>();
    final paylaterProvider = context.read<PaylaterProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final walletId = walletProvider.wallet?.id;

    if (userId == null || walletId == null) return;

    if (walletProvider.balance < bill.totalDue) {
      showSpSnackbar(context, 'Saldo tidak cukup untuk membayar tagihan',
          isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bayar Tagihan'),
        content: Text(
          'Bayar tagihan sebesar ${CurrencyFormatter.format(bill.totalDue)} dari saldo wallet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Bayar'),
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
        // ignore: use_build_context_synchronously
        context,
        paylaterProvider.errorMessage ?? 'Pembayaran gagal',
        isError: true,
      );
    }
  }
}

class _LimitInfo extends StatelessWidget {
  final String label;
  final String value;

  const _LimitInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final PaylaterBillModel bill;
  final VoidCallback? onPay; // Nullable untuk bill yang sudah dibayar

  const _BillCard({required this.bill, this.onPay});

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.isOverdue;
    final isPaid = bill.status == BillStatus.paid;
    
    return SpCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(bill.totalDue),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tenor: ${bill.tenorMonths} bulan',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid 
                    ? AppColors.successLight 
                    : isOverdue 
                      ? AppColors.errorLight 
                      : AppColors.secondaryLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? 'Lunas' : isOverdue ? 'Telat' : 'Aktif',
                  style: TextStyle(
                    color: isPaid 
                      ? AppColors.success 
                      : isOverdue 
                        ? AppColors.error 
                        : AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailChip(
                  label: 'Pokok',
                  value: CurrencyFormatter.format(bill.principalAmount),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailChip(
                  label: 'Bunga',
                  value: CurrencyFormatter.format(bill.interestAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPaid 
                  ? 'Dibayar: ${DateFormatter.formatDate(bill.paidAt ?? bill.dueDate)}'
                  : 'Jatuh Tempo: ${DateFormatter.formatDate(bill.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isPaid 
                    ? AppColors.success 
                    : isOverdue 
                      ? AppColors.error 
                      : AppColors.textSecondary,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              // Hanya tampilkan tombol bayar jika belum dibayar
              if (!isPaid && onPay != null)
                ElevatedButton(
                  onPressed: onPay,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('Bayar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
