import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';
import '../models/analysis_result.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  final String clientName;
  const ClientProfileScreen({super.key, required this.clientName});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool _isUploading = false;
  String _selectedMetric = 'hydration'; // Default metric to plot

  // Map of internal keys to translated/friendly Portuguese/French display names
  final List<Map<String, String>> _metrics = [
    {'key': 'hydration', 'pt': 'Hidratação', 'fr': 'Hydratation'},
    {'key': 'wrinkles', 'pt': 'Rugas', 'fr': 'Rides'},
    {'key': 'pores', 'pt': 'Poros', 'fr': 'Pores'},
    {'key': 'spots', 'pt': 'Manchas', 'fr': 'Taches'},
    {'key': 'texture', 'pt': 'Textura', 'fr': 'Texture'},
    {'key': 'acne', 'pt': 'Acne', 'fr': 'Acné'},
    {'key': 'elasticity', 'pt': 'Elasticidade', 'fr': 'Élasticité'},
    {'key': 'dark_circles', 'pt': 'Olheiras', 'fr': 'Cernes'},
  ];

  double _getMetricValue(SkinScores scores, String metricKey) {
    switch (metricKey) {
      case 'hydration':
        return scores.hydration;
      case 'wrinkles':
        return scores.wrinkles;
      case 'pores':
        return scores.pores;
      case 'spots':
        return scores.spots;
      case 'texture':
        return scores.texture;
      case 'acne':
        return scores.acne;
      case 'elasticity':
        return scores.elasticity;
      case 'dark_circles':
        return scores.darkCircles;
      default:
        return 0.0;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final bytes = await pickedFile.readAsBytes();
      final supabaseService = ref.read(supabaseServiceProvider);

      // Upload to Supabase Storage
      final photoUrl = await supabaseService.uploadClientPhoto(widget.clientName, bytes);

      // Sync across all analyses for this client
      await supabaseService.updateClientPhotoUrl(widget.clientName, photoUrl);

      // Invalidate provider to refresh lists
      ref.invalidate(analysesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppL10n.of(context, ref).t(
                'Foto de perfil atualizada com sucesso!',
                'Photo de profil mise à jour avec succès !',
              ),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppL10n.of(context, ref).t('Erro ao atualizar foto', 'Erreur de mise à jour photo')}: $e',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImageSourceActionSheet() {
    final l10n = AppL10n.of(context, ref);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.t('Alterar foto de rosto', 'Changer la photo de visage'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primarySalmon),
                title: Text(l10n.t('Tirar foto', 'Prendre une photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primarySalmon),
                title: Text(l10n.t('Escolher da galeria', 'Choisir depuis la galerie')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AnalysisResult analysis) {
    final l10n = AppL10n.of(context, ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('Apagar relatório?', 'Supprimer le rapport ?')),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(supabaseServiceProvider).deleteAnalysis(analysis.id);
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

  @override
  Widget build(BuildContext context) {
    final analysesState = ref.watch(analysesProvider);
    final l10n = AppL10n.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: analysesState.when(
        data: (list) {
          // Filter analyses for this specific client name
          final clientAnalyses = list.where((a) {
            return a.clientName?.trim().toLowerCase() == widget.clientName.trim().toLowerCase();
          }).toList();

          if (clientAnalyses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('Nenhum relatório encontrado', 'Aucun rapport trouvé'),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Chronological sorting
          final latestAnalysis = clientAnalyses.first; // Database output is DESC by createdAt
          final oldestToNewest = List<AnalysisResult>.from(clientAnalyses).reversed.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header profile card
                _buildProfileHeaderCard(latestAnalysis, clientAnalyses.length),
                const SizedBox(height: 24),

                // Evolution Chart card
                _buildEvolutionChartCard(oldestToNewest),
                const SizedBox(height: 24),

                // Historical list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('Histórico de Consultas', 'Historique des Consultations'),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySalmon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${clientAnalyses.length} ${clientAnalyses.length == 1 ? l10n.t('sessão', 'session') : l10n.t('sessões', 'sessions')}',
                        style: const TextStyle(
                          color: AppTheme.primarySalmon,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of past reports
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clientAnalyses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final analysis = clientAnalyses[index];
                    return _buildAnalysisListItem(analysis);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primarySalmon),
        ),
        error: (err, _) => Center(
          child: Text(
            '${l10n.t('Erro ao carregar perfil', 'Erreur de chargement profil')}: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(AnalysisResult latest, int reportCount) {
    final l10n = AppL10n.of(context, ref);
    final skinType = l10n.translateSkinType(latest.skinType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySalmon.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.primarySalmon.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Circular interactive avatar
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Hero(
                  tag: 'client_avatar_${widget.clientName}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primarySalmon, width: 2),
                    ),
                    child: ClipOval(
                      child: latest.faceImage != null && latest.faceImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: latest.faceImage!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                color: AppTheme.bgElevated,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primarySalmon,
                                  ),
                                ),
                              ),
                              errorWidget: (ctx, url, err) => _buildFallbackAvatar(),
                            )
                          : _buildFallbackAvatar(),
                    ),
                  ),
                ),
              ),
              if (_isUploading)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              // Camera button overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primarySalmon,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          // Info list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${l10n.t('Pele', 'Peau')} $skinType',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (latest.clientAge != null) '${latest.clientAge} ${l10n.t('anos', 'ans')}',
                    if (latest.skinAge != null) '${l10n.t('Idade Pele', 'Âge Peau')}: ${latest.skinAge}',
                  ].join(' • '),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final initial = widget.clientName.trim().isNotEmpty
        ? widget.clientName.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      color: AppTheme.bgElevated,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppTheme.primarySalmon,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildEvolutionChartCard(List<AnalysisResult> chronologicalList) {
    final l10n = AppL10n.of(context, ref);
    final activeMetricData = _metrics.firstWhere((m) => m['key'] == _selectedMetric);
    final activeLabel = l10n.t(activeMetricData['pt']!, activeMetricData['fr']!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySalmon.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.primarySalmon.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('Evolução Clínico-Estética', 'Évolution Clinico-Esthétique'),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable chips for selecting metrics
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _metrics.map((m) {
                final isSelected = m['key'] == _selectedMetric;
                final label = l10n.t(m['pt']!, m['fr']!);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMetric = m['key']!;
                        });
                      }
                    },
                    selectedColor: AppTheme.primarySalmon.withValues(alpha: 0.15),
                    backgroundColor: AppTheme.bgElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primarySalmon : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primarySalmon.withValues(alpha: 0.3)
                          : AppTheme.primarySalmon.withValues(alpha: 0.08),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Chart Display
          if (chronologicalList.length < 2)
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.t(
                      'Adicione mais relatórios M7 para visualizar a evolução gráfica desta métrica.',
                      'Ajoutez d\'autres rapports M7 pour visualiser l\'évolution graphique de cette métrique.',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.primarySalmon.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < chronologicalList.length) {
                            final date = chronologicalList[idx].createdAt;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppTheme.textPrimary.withValues(alpha: 0.95),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final date = chronologicalList[idx].createdAt;
                          final formattedDate = '${date.day}/${date.month}/${date.year}';
                          return LineTooltipItem(
                            '$activeLabel: ${spot.y.toStringAsFixed(1)}\n$formattedDate',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chronologicalList.length, (i) {
                        final val = _getMetricValue(chronologicalList[i].skinScores, _selectedMetric);
                        return FlSpot(i.toDouble(), val);
                      }),
                      isCurved: true,
                      barWidth: 4,
                      color: AppTheme.primarySalmon,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeColor: AppTheme.primarySalmon,
                          strokeWidth: 3,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primarySalmon.withValues(alpha: 0.25),
                            AppTheme.primarySalmon.withValues(alpha: 0.0),
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
        ],
      ),
    );
  }

  Widget _buildAnalysisListItem(AnalysisResult analysis) {
    final l10n = AppL10n.of(context, ref);
    final avgScore = analysis.skinScores.average;

    return GestureDetector(
      onTap: () => context.push('/analysis/result/${analysis.id}'),
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
            // Score circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.scoreColor(avgScore).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avgScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppTheme.scoreColor(avgScore),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.t('Consulta', 'Consultation')} - ${analysis.createdAt.day}/${analysis.createdAt.month}/${analysis.createdAt.year}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (analysis.skinAge != null) '${l10n.t('Idade pele', 'Âge peau')}: ${analysis.skinAge}',
                      '${analysis.recommendations.length} ${l10n.t('recomendações', 'recommandations')}',
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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
              onPressed: () => _confirmDelete(analysis),
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
  }
}
