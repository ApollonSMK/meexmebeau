import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? matchReason;
  final int? priority;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.matchReason,
    this.priority,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priority != null && priority! <= 2
                ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                : AppTheme.primarySalmon.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: AppTheme.bgElevated,
                          child: const Center(
                            child: Icon(
                              Icons.spa_outlined,
                              color: AppTheme.textMuted,
                              size: 32,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority badge
                  if (priority != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: priority! <= 2
                            ? AppTheme.primaryGradient
                            : null,
                        color: priority! > 2 ? AppTheme.bgElevated : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priority! <= 2
                            ? '⭐ TOP MATCH'
                            : '#$priority Recomendado',
                        style: TextStyle(
                          color: priority! <= 2
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // Brand
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

                  const SizedBox(height: 2),

                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Category
                  Text(
                    product.category,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),

                  // Price
                  if (product.price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '€${product.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.accentPink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  // Match reason
                  if (matchReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryPurpleLight,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              matchReason!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppTheme.bgElevated,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa_outlined, color: AppTheme.textMuted, size: 32),
            const SizedBox(height: 4),
            Text(
              product.category,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
