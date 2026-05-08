import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/incomes/presentation/add_income_page.dart';
import '../features/expenses/presentation/add_expense_page.dart';
import '../features/statistics/presentation/statistics_page.dart';
import '../features/goals/presentation/goals_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
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
      builder: (context, state) => const AddIncomePage(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const AddExpensePage(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const GoalsPage(),
    ),
  ],
);
