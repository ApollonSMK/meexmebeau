import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';
import '../widgets/skin_metric_gauge.dart';
import '../widgets/product_card.dart';
import '../models/analysis_result.dart';
import '../models/product.dart';

/// Provider that fetches a single analysis + its recommended products
final analysisDetailProvider = FutureProvider.family<
    ({AnalysisResult analysis, List<Product> products}), String>((ref, id) async {
  final supabase = ref.read(supabaseServiceProvider);
  final analysis = await supabase.getAnalysis(id);
  if (analysis == null) throw Exception('Análise não encontrada');

  final productIds = analysis.recommendations.map((r) => r.productId).toList();
  final products = await supabase.getProductsByIds(productIds);

  return (analysis: analysis, products: products);
});

class AnalysisDetailScreen extends ConsumerWidget {
  final String analysisId;
  const AnalysisDetailScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(analysisDetailProvider(analysisId));
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detail.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primarySalmon),
              const SizedBox(height: 16),
              Text(
                l10n.loadingAnalysis,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  '${l10n.t('Erro', 'Erreur')}: $e',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (data) => _buildResults(context, ref, data.analysis, data.products),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    AnalysisResult result,
    List<Product> products,
  ) {
    final l10n = AppL10n.of(context, ref);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client info
          if (result.clientName != null) ...[
            Text(
              result.clientName!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (result.clientAge != null) '${l10n.t('Idade', 'Âge')}: ${result.clientAge}',
                if (result.skinAge != null) '${l10n.t('Idade da Pele', 'Âge de la Peau')}: ${result.skinAge}',
              ].join(' • '),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
          ],

          // Date
          Text(
            '${result.createdAt.day}/${result.createdAt.month}/${result.createdAt.year} ${l10n.t('às', 'à')} ${result.createdAt.hour}:${result.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Skin type badge
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.face, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.t('Pele', 'Peau')} ${l10n.translateSkinType(result.skinType)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 20),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primarySalmon.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.analysisSummary,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Scores
          Text(
            l10n.skinScores,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoresGrid(result.skinScores),
          const SizedBox(height: 24),

          // Concerns
          if (result.concerns.isNotEmpty) ...[
            Text(
              l10n.identifiedConcerns,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.concerns
                  .map(
                    (c) => Chip(
                      label: Text(l10n.translateIndicator(c)),
                      avatar: const Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: AppTheme.warning,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Recommendations
          if (products.isNotEmpty) ...[
            Text(
              l10n.recommendedProducts,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.basedOnSkinAnalysis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildProductsList(context, ref, result, products),
          ],

          // Routine
          if (result.routineSuggestion != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primarySalmon.withValues(alpha: 0.1),
                    AppTheme.accentPeach.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primarySalmon.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primarySalmonLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.suggestedRoutine,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.routineSuggestion!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildScoresGrid(SkinScores scores) {
    final metrics = scores.toMap();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: metrics.length,
      itemBuilder: (ctx, i) {
        final entry = metrics.entries.elementAt(i);
        return SkinMetricGauge(
          label: entry.key,
          value: entry.value,
        ).animate().fadeIn(delay: Duration(milliseconds: 300 + i * 100));
      },
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    WidgetRef ref,
    AnalysisResult result,
    List<Product> products,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final product = products[i];
        final rec = result.recommendations
            .where((r) => r.productId == product.id)
            .firstOrNull;
        return ProductCard(
          product: product,
          matchReason: rec?.reason,
          priority: rec?.priority,
          onTap: () => context.push('/products/${product.id}'),
        ).animate().fadeIn(delay: Duration(milliseconds: 600 + i * 100));
      },
    );
  }
}
