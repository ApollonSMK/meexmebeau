import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';
import '../models/analysis_result.dart';

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

          // Grouping logic:
          // We group analyses by clientName.
          // If clientName is null or empty, we keep it as a separate individual client group,
          // so anonymous reports don't all merge together.
          final Map<String, List<AnalysisResult>> groupedClients = {};
          final List<AnalysisResult> anonymousAnalyses = [];

          for (final a in list) {
            final name = a.clientName?.trim();
            if (name != null && name.isNotEmpty) {
              groupedClients.putIfAbsent(name, () => []).add(a);
            } else {
              anonymousAnalyses.add(a);
            }
          }

          // Build a list of items for the ListView.
          // A client item will hold the client name, and a list of all their analyses.
          // An anonymous item will represent a single anonymous analysis.
          final List<dynamic> historyItems = [];
          
          groupedClients.forEach((name, clientList) {
            historyItems.add({
              'isGroup': true,
              'name': name,
              'analyses': clientList,
              'latest': clientList.first, // ordered DESC from database
            });
          });

          for (final a in anonymousAnalyses) {
            historyItems.add({
              'isGroup': false,
              'analysis': a,
            });
          }

          // Sort historyItems by latest analysis date descending
          historyItems.sort((x, y) {
            final DateTime dx = x['isGroup'] ? x['latest'].createdAt : x['analysis'].createdAt;
            final DateTime dy = y['isGroup'] ? y['latest'].createdAt : y['analysis'].createdAt;
            return dy.compareTo(dx);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: historyItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final item = historyItems[i];

              if (item['isGroup']) {
                final String name = item['name'];
                final List<AnalysisResult> clientList = item['analyses'];
                final AnalysisResult latest = item['latest'];

                return GestureDetector(
                  onTap: () => context.push('/client/${Uri.encodeComponent(name)}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primarySalmon.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(latest.faceImage, name),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  '${clientList.length} ${clientList.length == 1 ? l10n.t('relatório', 'rapport') : l10n.t('relatórios', 'rapports')}',
                                  '${l10n.t('Pele', 'Peau')} ${l10n.translateSkinType(latest.skinType)}',
                                  if (latest.clientAge != null) '${latest.clientAge} ${l10n.t('anos', 'ans')}',
                                ].join(' • '),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.t('Última', 'Dernière')}: ${latest.createdAt.day}/${latest.createdAt.month}/${latest.createdAt.year}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final AnalysisResult a = item['analysis'];
                final label = l10n.t('Cliente Anónimo', 'Client Anonyme');

                return GestureDetector(
                  onTap: () => context.push('/analysis/result/${a.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primarySalmon.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(a.faceImage, 'A'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (a.clientAge != null) '${l10n.t('Idade', 'Âge')}: ${a.clientAge}',
                                  '${l10n.t('Pele', 'Peau')} ${l10n.translateSkinType(a.skinType)}',
                                ].join(' • '),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year} ${a.createdAt.hour}:${a.createdAt.minute.toString().padLeft(2, '0')}',
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
              }
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

  Widget _buildAvatar(String? imageUrl, String? name) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 48,
            height: 48,
            color: AppTheme.bgElevated,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySalmon),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackAvatar(name),
        ),
      );
    }
    return _buildFallbackAvatar(name);
  }

  Widget _buildFallbackAvatar(String? name) {
    final initial = name != null && name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
