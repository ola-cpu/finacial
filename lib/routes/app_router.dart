import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/incomes/presentation/add_income_page.dart';
import '../features/expenses/presentation/add_expense_page.dart';
import '../features/statistics/presentation/statistics_page.dart';
import '../features/goals/presentation/goals_page.dart';
import '../features/analytics/presentation/analytics_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/login';

    if (session == null) {
      return isLoggingIn ? null : '/login';
    }

    if (isLoggingIn) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/add-income',
      builder: (context, state) => AddIncomePage(income: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => AddExpensePage(expense: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const GoalsPage(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsPage(),
    ),
  ],
);
