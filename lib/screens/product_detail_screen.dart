import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('Produto', 'Produit'))),
      body: products.when(
        data: (list) {
          final product = list.where((p) => p.id == productId).firstOrNull;
          if (product == null) {
            return Center(
              child: Text(
                l10n.t('Produto não encontrado', 'Produit non trouvé'),
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            height: 260,
                            color: AppTheme.bgCard,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(height: 20),

                // Brand
                if (product.brand != null)
                  Text(
                    product.brand!.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryPurpleLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 4),

                // Name
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translateCategory(product.category),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),

                // Price
                if (product.price != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '€${product.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accentPink,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Description
                if (product.description != null) ...[
                  Text(
                    l10n.t('Descrição', 'Description'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Skin Types
                if (product.skinTypes.isNotEmpty) ...[
                  Text(
                    l10n.t('Tipos de Pele', 'Types de Peau'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.skinTypes
                        .map(
                          (t) => Chip(
                            label: Text(l10n.translateSkinType(t)),
                            avatar: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppTheme.success,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Concerns
                if (product.skinConcerns.isNotEmpty) ...[
                  Text(
                    l10n.t('Indicações', 'Indications'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.skinConcerns
                        .map((c) => Chip(label: Text(l10n.translateIndicator(c))))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Ingredients
                if (product.ingredients != null) ...[
                  Text(
                    l10n.t('Ingredientes', 'Ingrédients'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.ingredients!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.t('Erro', 'Erreur')}: $e')),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 260,
      color: AppTheme.bgCard,
      child: const Center(
        child: Icon(
          Icons.spa_outlined,
          size: 64,
          color: AppTheme.primaryPurpleLight,
        ),
      ),
    );
  }
}
