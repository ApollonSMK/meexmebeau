import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/l10n.dart';
import '../../providers/providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('Painel Admin', 'Panneau Admin')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            stats.when(
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _statCard(
                      l10n.products,
                      '${s.productCount}',
                      Icons.spa_outlined,
                      AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      l10n.t('Análises', 'Analyses'),
                      '${s.analysisCount}',
                      Icons.analytics_outlined,
                      AppTheme.accentPink,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 32),

            Text(
              l10n.t('Gestão', 'Gestion'),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            _menuItem(
              context,
              l10n.manageProducts,
              l10n.t('Adicionar, editar e remover', 'Ajouter, modifier et supprimer'),
              Icons.spa_outlined,
              () => context.push('/admin/products'),
            ),
            const SizedBox(height: 8),
            _menuItem(
              context,
              l10n.t('Ver Análises', 'Voir les Analyses'),
              l10n.t('Histórico de todas as análises', 'Historique de toutes les analyses'),
              Icons.history,
              () => context.push('/history'),
            ),
            const SizedBox(height: 8),
            _menuItem(
              context,
              l10n.t('Ver Catálogo', 'Voir le Catalogue'),
              l10n.t('Como os utilizadores veem', 'Comment les utilisateurs le voient'),
              Icons.visibility_outlined,
              () => context.push('/products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext ctx,
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurpleLight, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
