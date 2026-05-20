import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyses = ref.watch(analysesProvider);
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: analyses.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('Sem histórico', 'Aucun historique'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    l10n.t('As análises feitas aparecerão aqui', 'Les analyses effectuées apparaîtront ici'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final a = list[i];
              return GestureDetector(
                onTap: () => context.push('/analysis/result/${a.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primarySalmon.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.face,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.clientName ?? '${l10n.t('Pele', 'Peau')} ${l10n.translateSkinType(a.skinType)}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (a.clientAge != null) '${l10n.t('Idade', 'Âge')}: ${a.clientAge}',
                                if (a.skinAge != null) '${l10n.t('Idade da Pele', 'Âge de la Peau')}: ${a.skinAge}',
                                '${l10n.t('Pele', 'Peau')} ${l10n.translateSkinType(a.skinType)}',
                              ].join(' • '),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.recommendations.length} ${l10n.t('produtos', 'produits')} • ${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year} ${a.createdAt.hour}:${a.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, ref, a.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '${l10n.t('Erro', 'Erreur')}: $e',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppL10n.of(context, ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('Apagar análise?', 'Supprimer l\'analyse ?')),
        content: Text(l10n.t('Esta ação não pode ser desfeita.', 'Cette action ne peut pas être annulée.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(supabaseServiceProvider).deleteAnalysis(id);
              ref.invalidate(analysesProvider);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
