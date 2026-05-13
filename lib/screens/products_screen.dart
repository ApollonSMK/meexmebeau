import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Produtos')),
      body: products.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_outlined, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum produto disponível',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Adicione produtos na secção Admin',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Group by category
          final grouped = <String, List<dynamic>>{};
          for (final p in list) {
            grouped.putIfAbsent(p.category, () => []).add(p);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final cat = grouped.keys.elementAt(i);
              final items = grouped[cat]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 24),
                  Text(
                    cat,
                    style: const TextStyle(
                      color: AppTheme.primaryPurpleLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.asMap().entries.map(
                    (e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _productTile(context, e.value),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 100 * e.key),
                        ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erro: $e',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _productTile(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.spa,
                color: AppTheme.primaryPurpleLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand != null)
                    Text(
                      product.brand!.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryPurpleLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (product.price != null)
              Text(
                '€${product.price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.accentPink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
