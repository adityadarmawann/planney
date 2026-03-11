import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/paylater_repository.dart';
import 'data/repositories/expense_plan_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/paylater_provider.dart';
import 'providers/expense_plan_provider.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/main_screen.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/wallet/wallet_screen.dart';
import 'presentation/screens/wallet/topup_screen.dart';
import 'presentation/screens/wallet/topup_success_screen.dart';
import 'presentation/screens/transfer/transfer_screen.dart';
import 'presentation/screens/transfer/transfer_confirm_screen.dart';
import 'presentation/screens/transfer/transfer_success_screen.dart';
import 'presentation/screens/transfer/qris_simulator_screen.dart';
import 'presentation/screens/transfer/qris_payment_screen.dart';
import 'presentation/screens/paylater/paylater_screen.dart';
import 'presentation/screens/paylater/paylater_apply_screen.dart';
import 'presentation/screens/paylater/paylater_bill_screen.dart';
import 'presentation/screens/budget/budget_create_screen.dart';
import 'presentation/screens/budget/budget_detail_screen.dart';
import 'presentation/screens/expense_plan/expense_plan_calendar_screen.dart';
import 'presentation/screens/expense_plan/expense_plan_create_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/history/transaction_detail_screen.dart';

// Initialize GoogleSignIn instance (singleton pattern)
final _googleSignIn = GoogleSignIn.instance;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Repositories
    final authRepo = AuthRepository(
      client: supabase,
      googleSignIn: _googleSignIn,
    );
    final userRepo = UserRepository(client: supabase);
    final walletRepo = WalletRepository(client: supabase);
    final txRepo = TransactionRepository(
      client: supabase,
      walletRepository: walletRepo,
    );
    final budgetRepo = BudgetRepository(client: supabase);
    final paylaterRepo = PaylaterRepository(
      client: supabase,
      walletRepository: walletRepo,
    );
    final expensePlanRepo = ExpensePlanRepository(client: supabase);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepository: authRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => UserProvider(userRepository: userRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => WalletProvider(walletRepository: walletRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => TransactionProvider(
              transactionRepository: txRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => BudgetProvider(budgetRepository: budgetRepo),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                PaylaterProvider(paylaterRepository: paylaterRepo),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                ExpensePlanProvider(repository: expensePlanRepo),
          ),
        ],
        child: MaterialApp(
        title: 'Planney',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const MainScreen(),
          AppRoutes.editProfile: (_) => const EditProfileScreen(),
          AppRoutes.wallet: (_) => const WalletScreen(),
          AppRoutes.topup: (_) => const TopupScreen(),
          AppRoutes.topupSuccess: (_) => const TopupSuccessScreen(),
          AppRoutes.transfer: (_) => const TransferScreen(),
          AppRoutes.transferConfirm: (_) => const TransferConfirmScreen(),
          AppRoutes.transferSuccess: (_) => const TransferSuccessScreen(),
          AppRoutes.qrisSimulator: (_) => const QrisSimulatorScreen(),
          AppRoutes.qrisPayment: (_) => const QrisPaymentScreen(),
          AppRoutes.paylater: (_) => const PaylaterScreen(),
          AppRoutes.paylaterApply: (_) => const PaylaterApplyScreen(),
          AppRoutes.paylaterBill: (_) => const PaylaterBillScreen(),
          AppRoutes.budgetCreate: (_) => const BudgetCreateScreen(),
          AppRoutes.budgetDetail: (_) => const BudgetDetailScreen(),
          AppRoutes.expensePlanCalendar: (_) => const ExpensePlanCalendarScreen(),
          AppRoutes.expensePlanCreate: (_) => const ExpensePlanCreateScreen(),
          AppRoutes.history: (_) => const HistoryScreen(),
          AppRoutes.transactionDetail: (_) =>
              const TransactionDetailScreen(),
        },
      ),
      ),
    );
  }
}
