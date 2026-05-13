import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/rapport_analysis_screen.dart';
import 'screens/products_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin/admin_login.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_products.dart';
import 'screens/admin/admin_product_form.dart';
import 'screens/analysis_detail_screen.dart';
import 'config/theme.dart';

class MeApp extends StatelessWidget {
  const MeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MEBeauty IA',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/analysis',
      builder: (_, _) => const RapportAnalysisScreen(),
    ),
    GoRoute(
      path: '/analysis/result/:id',
      builder: (_, state) => AnalysisDetailScreen(
        analysisId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
    GoRoute(
      path: '/products/:id',
      builder: (_, state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
    GoRoute(path: '/admin/login', builder: (_, _) => const AdminLoginScreen()),
    GoRoute(path: '/admin', builder: (_, _) => const AdminDashboard()),
    GoRoute(
      path: '/admin/products',
      builder: (_, _) => const AdminProductsScreen(),
    ),
    GoRoute(
      path: '/admin/products/new',
      builder: (_, _) => const AdminProductForm(),
    ),
    GoRoute(
      path: '/admin/products/edit/:id',
      builder: (_, state) =>
          AdminProductForm(productId: state.pathParameters['id']),
    ),
  ],
);
