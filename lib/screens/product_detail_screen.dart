import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';
import '../models/product.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  void _showFullScreenImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            body: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primarySalmon,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      body: products.when(
        data: (list) {
          final product = list.where((p) => p.id == productId).firstOrNull;
          if (product == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.t('Produto', 'Produit'))),
              body: Center(
                child: Text(
                  l10n.t('Produto não encontrado', 'Produit non trouvé'),
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 340.0,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: GestureDetector(
                      onTap: () => _showFullScreenImage(context, product.imageUrl),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'product_image_${product.id}',
                            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(
                                      color: AppTheme.bgCard,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primarySalmon,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, _, _) => _imagePlaceholder(),
                                  )
                                : _imagePlaceholder(),
                          ),
                          // Premium dark elegant bottom gradient
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black45,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Clinical vs Homecare Banner
                  _buildInternalCareBanner(context, l10n, product.isInternal),
                  const SizedBox(height: 20),

                  // 2. Brand & Name Header
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primarySalmon,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySalmon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.translateCategory(product.category),
                          style: const TextStyle(
                            color: AppTheme.primarySalmon,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Price Card
                  _buildPriceCard(context, l10n, product.price, product.specialPrice),
                  const SizedBox(height: 20),

                  // 4. Principal Attribute Highlight Banner
                  if (product.productAttribute != null && product.productAttribute!.isNotEmpty) ...[
                    _buildAttributeBanner(context, l10n, product.productAttribute!),
                    const SizedBox(height: 20),
                  ],

                  // 5. Usage Method Box
                  if (product.usageMethod != null && product.usageMethod!.isNotEmpty) ...[
                    _buildUsageMethodCard(context, l10n, product.usageMethod!),
                    const SizedBox(height: 24),
                  ],

                  // 6. Demographics Grid
                  _buildDemographicsGrid(context, l10n, product),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 20),

                  // 7. Description Section
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    _buildSectionHeader(l10n.t('Descrição', 'Description')),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 8. Skin Types Section
                  if (product.skinTypes.isNotEmpty) ...[
                    _buildSectionHeader(l10n.t('Tipos de Pele', 'Types de Peau')),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.skinTypes.map((t) => _buildSkinTypeChip(l10n, t)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 9. Clinical M7 Indicators Section
                  if (product.indicatorCorrelation.isNotEmpty) ...[
                    _buildSectionHeader(l10n.t('Indicadores M7', 'Indicateurs M7')),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.indicatorCorrelation.map((ind) => _buildIndicatorChip(l10n, ind)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 10. Ingredients Section
                  if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                    _buildIngredientsSection(context, l10n, product.ingredients!),
                    const SizedBox(height: 24),
                  ],

                  // 11. Website CTA Button
                  if (product.website != null && product.website!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildWebsiteButton(context, l10n, product.website!),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primarySalmon,
            ),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(
            child: Text(
              '${l10n.t('Erro', 'Erreur')}: $e',
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      color: AppTheme.bgCard,
      child: const Center(
        child: Icon(
          Icons.spa_outlined,
          size: 72,
          color: AppTheme.primarySalmonLight,
        ),
      ),
    );
  }

  Widget _buildInternalCareBanner(BuildContext context, AppL10n l10n, bool isInternal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isInternal
            ? AppTheme.primarySalmon.withValues(alpha: 0.08)
            : AppTheme.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInternal
              ? AppTheme.primarySalmon.withValues(alpha: 0.2)
              : AppTheme.success.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isInternal ? Icons.admin_panel_settings_outlined : Icons.home_outlined,
            color: isInternal ? AppTheme.primarySalmon : AppTheme.success,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInternal ? l10n.clinicOnly : l10n.homecareUse,
                  style: TextStyle(
                    color: isInternal ? AppTheme.primarySalmon : AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isInternal
                      ? l10n.clinicOnlySub
                      : l10n.t(
                          'Recomendado para rotina diária em casa',
                          'Recommandé pour la routine quotidienne à la maison',
                        ),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, AppL10n l10n, double? price, double? specialPrice) {
    if (price == null && specialPrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.price,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (specialPrice != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price != null)
                  Text(
                    '€${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '€${specialPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.accentPink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ] else if (price != null) ...[
            Text(
              '€${price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributeBanner(BuildContext context, AppL10n l10n, String attribute) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primarySalmon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.primarySalmon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attribute,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMethodCard(BuildContext context, AppL10n l10n, String usageMethod) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPeachLight.withValues(alpha: 0.15),
            AppTheme.accentPeach.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentPeach.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppTheme.primarySalmon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usageMethod,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usageMethod,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsGrid(BuildContext context, AppL10n l10n, Product product) {
    final List<Widget> items = [];

    // Gender
    if (product.applicableGender != null && product.applicableGender!.isNotEmpty) {
      items.add(
        _buildDemographicPill(
          icon: Icons.wc_outlined,
          label: l10n.gender,
          value: l10n.translateGender(product.applicableGender),
        ),
      );
    }

    // Crowd
    if (product.applicableCrowd.isNotEmpty) {
      items.add(
        _buildDemographicPill(
          icon: Icons.group_outlined,
          label: l10n.crowd,
          value: product.applicableCrowd.map((c) => l10n.translateCrowd(c)).join(', '),
        ),
      );
    }

    // Skin Condition
    if (product.applicationSkin != null && product.applicationSkin!.isNotEmpty) {
      items.add(
        _buildDemographicPill(
          icon: Icons.auto_graph_outlined,
          label: l10n.fieldSkinCondition.replaceFirst(' *', ''),
          value: l10n.translateSkinCondition(product.applicationSkin),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items,
    );
  }

  Widget _buildDemographicPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySalmon.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primarySalmon, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSkinTypeChip(AppL10n l10n, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primarySalmon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_outlined, color: AppTheme.primarySalmon, size: 14),
          const SizedBox(width: 6),
          Text(
            l10n.translateSkinType(type),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(AppL10n l10n, String indicator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentPeach.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentPeach.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primarySalmon, size: 14),
          const SizedBox(width: 6),
          Text(
            l10n.translateIndicator(indicator),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context, AppL10n l10n, String ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.ingredients),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
          ),
          child: Text(
            ingredients,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebsiteButton(BuildContext context, AppL10n l10n, String websiteUrl) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(websiteUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.t(
                      'Não foi possível abrir o website',
                      'Impossible d\'ouvrir le site Web',
                    ),
                  ),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.language, size: 20),
        label: Text(l10n.visitWebsite),
      ),
    );
  }
}
