import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/home/balance_card.dart';
import '../../widgets/home/quick_action_grid.dart';
import '../../widgets/home/wallet_summary_chart.dart';
import '../../widgets/transaction/transaction_tile.dart';
import '../../widgets/common/sp_loading.dart';
import '../../widgets/common/sp_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    await Future.wait([
      context.read<WalletProvider>().loadWallet(userId),
      context.read<TransactionProvider>().loadTransactions(userId: userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final wallet = context.watch<WalletProvider>().wallet;
    final txProvider = context.watch<TransactionProvider>();
    final recentTx = txProvider.transactions.take(5).toList();
    final firstName = user?.fullName.split(' ').first ?? 'Pengguna';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Greeting with logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelola keuanganmu dengan bijak',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                // Planney logo
                Image.asset(
                  'assets/images/logo-planney.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Balance Card
            BalanceCard(
              balance: wallet?.balance ?? 0,
              userName: firstName,
            ),
            const SizedBox(height: 28),
            const Text(
              AppStrings.quickActions,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SpCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: QuickActionGrid(
                onTopUp: () => Navigator.pushNamed(context, AppRoutes.topup)
                    .then((_) => _loadData()),
                onTransfer: () =>
                    Navigator.pushNamed(context, AppRoutes.transfer)
                        .then((_) => _loadData()),
                onRencana: () =>
                  Navigator.pushNamed(context, AppRoutes.expensePlanCalendar),
                onPayLater: () =>
                  Navigator.pushNamed(context, AppRoutes.paylater),
              ),
            ),
            const SizedBox(height: 28),
            // Wallet Summary Chart
            const Text(
              'Ringkasan Dompet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SpCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: WalletSummaryChart(
                transactions: txProvider.transactions,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.recentTransactions,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.history),
                  child: const Text(AppStrings.seeAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (txProvider.isLoading)
              const SpLoading()
            else if (recentTx.isEmpty)
              const SpCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SpCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  children: recentTx
                      .map(
                        (tx) => TransactionTile(
                          transaction: tx,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.transactionDetail,
                            arguments: tx,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
