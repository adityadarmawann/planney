import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/paylater_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/sp_button.dart';
import '../../widgets/common/sp_snackbar.dart';
import '../../widgets/payment/payment_method_selector.dart';
import 'transfer_screen.dart';

class TransferConfirmScreen extends StatefulWidget {
  const TransferConfirmScreen({super.key});

  @override
  State<TransferConfirmScreen> createState() => _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends State<TransferConfirmScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.wallet;
  int _selectedTenor = 3;
  bool _payLaterLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_payLaterLoaded) return;

    _payLaterLoaded = true;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final type = args['type'] as TransferType;
    if (type == TransferType.qris) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPayLaterAccount());
    }
  }

  Future<void> _loadPayLaterAccount() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<PaylaterProvider>().loadAccount(userId);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final type = args['type'] as TransferType;
    final amount = args['amount'] as double;
    final fee = (args['fee'] as double?) ?? 0;
    final note = args['note'] as String? ?? '';

    final paylaterProvider = context.watch<PaylaterProvider>();
    final canUsePayLater = type == TransferType.qris;

    final isLoading = context.watch<TransactionProvider>().isLoading ||
      (canUsePayLater && paylaterProvider.isLoading);
    final walletBalance = context.watch<WalletProvider>().balance;
    final paylaterAccount = paylaterProvider.account;
    final paylaterLimit = paylaterAccount?.remainingLimit ?? 0;
    final interestRate = paylaterAccount?.interestRate ?? 2.5;

    return Scaffold(
      appBar: AppBar(
        title: Text('Konfirmasi Transfer'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Transfer icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type == TransferType.qris
                            ? Icons.qr_code_2_rounded
                            : Icons.send_rounded,
                        size: 36,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == TransferType.user
                          ? 'Transfer ke Pengguna'
                          : type == TransferType.bank
                              ? 'Transfer ke Bank'
                              : 'Pembayaran QRIS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (type == TransferType.user) ...[
                            _DetailRow(
                              label: 'Penerima',
                              value:
                                  '${(args['recipient'] as UserModel).fullName}\n@${(args['recipient'] as UserModel).username}',
                            ),
                          ] else if (type == TransferType.bank) ...[
                            _DetailRow(
                                label: 'Bank', value: args['bankName'] as String),
                            _DetailRow(
                                label: 'No. Rekening',
                                value: args['accountNumber'] as String),
                          ] else if (type == TransferType.qris) ...[
                            _DetailRow(
                              label: 'Merchant',
                              value: args['merchant'] as String? ?? 'Warung UMKM Indonesia',
                            ),
                          ],
                          _DetailRow(
                            label: 'Jumlah',
                            value: CurrencyFormatter.format(amount),
                            valueStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (fee > 0)
                            _DetailRow(
                              label: 'Biaya Admin',
                              value: CurrencyFormatter.format(fee),
                            ),
                          if (fee > 0) const Divider(height: 24),
                          if (fee > 0)
                            _DetailRow(
                              label: 'Total',
                              value: CurrencyFormatter.format(amount + fee),
                              valueStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          if (note.isNotEmpty) ...[
                            const Divider(height: 24),
                            _DetailRow(label: 'Catatan', value: note),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Payment Method Selector
                    if (canUsePayLater)
                      PaymentMethodSelector(
                        selectedMethod: _paymentMethod,
                        selectedTenor: _selectedTenor,
                        amount: amount + fee,
                        walletBalance: walletBalance,
                        paylaterLimit: paylaterLimit,
                        interestRate: interestRate,
                        onMethodChanged: (method) {
                          setState(() => _paymentMethod = method);
                        },
                        onTenorChanged: (tenor) {
                          setState(() => _selectedTenor = tenor);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SpButton(
              text: _paymentMethod == PaymentMethod.paylater
                  ? 'Bayar dengan PayLater'
                  : 'Konfirmasi & Transfer',
              onPressed: () => _processTransfer(context, args, type),
              isLoading: isLoading,
            ),
            const SizedBox(height: 8),
            SpButton(
              text: 'Batal',
              onPressed: () => Navigator.pop(context),
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processTransfer(
    BuildContext context,
    Map<String, dynamic> args,
    TransferType type,
  ) async {
    final txProvider = context.read<TransactionProvider>();
    final paylaterProvider = context.read<PaylaterProvider>();
    final walletProvider = context.read<WalletProvider>();
    final authProvider = context.read<AuthProvider>();
    final amount = args['amount'] as double;
    final fee = (args['fee'] as double?) ?? 0;
    bool success = false;

    // PayLater hanya untuk QRIS
    if (type == TransferType.qris && _paymentMethod == PaymentMethod.paylater) {
      final merchantName = args['merchant'] as String? ?? 'Warung UMKM Indonesia';
      success = await paylaterProvider.payWithPaylaterQris(
        userId: args['senderId'] as String,
        walletId: args['senderWalletId'] as String,
        amount: amount,
        tenorMonths: _selectedTenor,
        merchantName: merchantName,
        merchantCity: 'N/A',
      );
    }
    // Gunakan wallet (default)
    else {
      if (type == TransferType.user) {
        final senderId = args['senderId'] as String;
        final receiverId = args['receiverId'] as String;
        if (senderId == receiverId) {
          showSpSnackbar(
            context,
            'Tidak bisa transfer ke akun sendiri',
            isError: true,
          );
          return;
        }

        success = await txProvider.transfer(
          senderId: senderId,
          senderWalletId: args['senderWalletId'] as String,
          receiverId: receiverId,
          receiverWalletId: args['receiverWalletId'] as String,
          amount: amount,
          note: args['note'] as String?,
        );
      } else if (type == TransferType.bank) {
        success = await txProvider.bankTransfer(
          userId: args['senderId'] as String,
          walletId: args['senderWalletId'] as String,
          amount: amount,
          fee: fee,
          bankName: args['bankName'] as String,
          accountNumber: args['accountNumber'] as String,
          note: args['note'] as String?,
        );
      } else if (type == TransferType.qris) {
        success = await txProvider.qrisPayment(
          userId: args['senderId'] as String,
          walletId: args['senderWalletId'] as String,
          amount: amount,
          merchantName: args['merchant'] as String? ?? 'Warung UMKM Indonesia',
        );
      }
    }

    if (!context.mounted) return;

    if (success) {
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        await walletProvider.loadWallet(userId);
      }
    }

    if (!context.mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.transferSuccess,
        arguments: {
          'type': type == TransferType.user ? 'user' : type == TransferType.bank ? 'bank' : 'qris',
          'amount': amount,
          'refCode': _paymentMethod == PaymentMethod.paylater 
            ? 'PL-${paylaterProvider.bills.first.id.substring(0, 8).toUpperCase()}' 
            : txProvider.lastTransaction?.refCode ?? '',
          'paymentMethod': _paymentMethod == PaymentMethod.paylater ? 'paylater' : 'wallet',
          'tenor': _paymentMethod == PaymentMethod.paylater ? _selectedTenor : null,
          if (type == TransferType.user)
            'recipient':
                (args['recipient'] as UserModel).fullName,
          if (type == TransferType.bank) 'bankName': args['bankName'],
          if (type == TransferType.qris) 'merchant': args['merchant'] as String? ?? 'Warung UMKM Indonesia',
        },
      );
    } else {
      showSpSnackbar(
        context,
        txProvider.errorMessage ?? 'Transfer gagal',
        isError: true,
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle ??
                  TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
