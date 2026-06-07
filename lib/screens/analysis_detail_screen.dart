import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../config/l10n.dart';
import '../providers/providers.dart';
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

class AnalysisDetailScreen extends ConsumerStatefulWidget {
  final String analysisId;
  const AnalysisDetailScreen({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends ConsumerState<AnalysisDetailScreen> {
  int _selectedTab = 0;
  int _selectedSummaryTab = 0;
  bool _uploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(analysisDetailProvider(widget.analysisId));
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
        data: (data) => Stack(
          children: [
            _buildResults(context, ref, data.analysis, data.products),
            if (_uploadingPhoto)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primarySalmon,
                  ),
                ),
              ),
          ],
        ),
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
    final parsedSummary = _parseSummary(result.summary);
    
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
          const SizedBox(height: 24),

          // Radar Chart of Skin Scores
          Text(
            l10n.skinScores,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildRadarChartContainer(result.skinScores, l10n).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Divided Text Summary Tabs
          Text(
            l10n.analysisSummary,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryTabs(parsedSummary).animate().fadeIn(delay: 300.ms, duration: 450.ms),
          const SizedBox(height: 28),

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
            const SizedBox(height: 28),
          ],

          // Routine Suggestions timeline
          if (result.routineSuggestion != null) ...[
            _buildRoutineSection(result.routineSuggestion!, l10n).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            const SizedBox(height: 28),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(l10n.routineHome),
                    icon: const Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(l10n.treatmentClinic),
                    icon: const Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (set) {
                  setState(() => _selectedTab = set.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryPurple.withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryPurpleLight;
                    }
                    return AppTheme.textSecondary;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (ctx) {
                final isInternalView = _selectedTab == 1;
                final filteredProducts = products
                    .where((p) => p.isInternal == isInternalView)
                    .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        isInternalView
                            ? l10n.noClinicRecommended
                            : l10n.noHomeRecommended,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return _buildProductsGrid(result, filteredProducts);
              },
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRadarChartContainer(SkinScores scores, AppL10n l10n) {
    final englishKeys = [
      'hydration',
      'wrinkles',
      'pores',
      'spots',
      'texture',
      'acne',
      'elasticity',
      'dark_circles',
    ];
    final values = [
      scores.hydration,
      scores.wrinkles,
      scores.pores,
      scores.spots,
      scores.texture,
      scores.acne,
      scores.elasticity,
      scores.darkCircles,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primarySalmon.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 260,
            padding: const EdgeInsets.all(8),
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                    borderColor: AppTheme.primaryPurple,
                    fillColor: AppTheme.primaryPurple.withValues(alpha: 0.15),
                    borderWidth: 2.5,
                    entryRadius: 4,
                  ),
                  // Invisible dummy set to force scale limit to 10
                  RadarDataSet(
                    dataEntries: List.generate(8, (_) => const RadarEntry(value: 10)),
                    borderColor: Colors.transparent,
                    fillColor: Colors.transparent,
                    entryRadius: 0,
                  ),
                ],
                radarBorderData: const BorderSide(color: AppTheme.textMuted, width: 0.5),
                gridBorderData: BorderSide(color: AppTheme.primarySalmon.withValues(alpha: 0.1), width: 0.5),
                tickBorderData: BorderSide(color: AppTheme.primarySalmon.withValues(alpha: 0.15), width: 0.5),
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                getTitle: (index, angle) {
                  final key = englishKeys[index];
                  final label = l10n.translateMetric(key);
                  return RadarChartTitle(
                    text: label,
                    angle: angle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Scores list summary
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(8, (index) {
              final key = englishKeys[index];
              final label = l10n.translateMetric(key);
              final val = values[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primarySalmon.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$label: ',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    Text(
                      val.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppTheme.scoreColor(val),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTabs(Map<String, String> parsedSummary) {
    final tabs = parsedSummary.keys.toList();
    if (tabs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Headers
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tabName = tabs[i];
              final isSelected = _selectedSummaryTab == i;
              IconData icon;
              switch (tabName) {
                case 'Diagnóstico': icon = Icons.medical_services_outlined; break;
                case 'Indicadores': icon = Icons.bar_chart_outlined; break;
                case 'Ativos': icon = Icons.science_outlined; break;
                case 'Tratamento': icon = Icons.spa_outlined; break;
                default: icon = Icons.article_outlined;
              }
              return GestureDetector(
                onTap: () => setState(() => _selectedSummaryTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryPurple : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.primarySalmon.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryPurpleLight, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        tabName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // Tab Content
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primarySalmon.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            parsedSummary[tabs[_selectedSummaryTab]] ?? '',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineSection(String routineText, AppL10n l10n) {
    final parsedRoutine = _parseRoutine(routineText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.suggestedRoutine,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Morning Routine
            if (parsedRoutine.containsKey('Manhã'))
              Expanded(
                child: _buildRoutineCard(
                  title: l10n.t('Ritual Matinal', 'Rituel Matinal'),
                  icon: Icons.light_mode,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.06),
                      AppTheme.primarySalmon.withValues(alpha: 0.02),
                    ],
                  ),
                  iconColor: Colors.orange,
                  content: parsedRoutine['Manhã']!,
                ),
              ),
            if (parsedRoutine.containsKey('Manhã') && parsedRoutine.containsKey('Noite'))
              const SizedBox(width: 12),
            // Night Routine
            if (parsedRoutine.containsKey('Noite'))
              Expanded(
                child: _buildRoutineCard(
                  title: l10n.t('Ritual Noturno', 'Rituel de Nuit'),
                  icon: Icons.dark_mode,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.06),
                      AppTheme.accentPink.withValues(alpha: 0.02),
                    ],
                  ),
                  iconColor: AppTheme.primaryPurpleLight,
                  content: parsedRoutine['Noite']!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required Color iconColor,
    required String content,
  }) {
    final steps = content.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((step) {
            final cleanStep = step.replaceFirst(RegExp(r'^(\d+\.|\-|\*)\s*'), '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cleanStep,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildScannerGallery(AnalysisResult result, AppL10n l10n) {
    final images = result.spectrumImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('Fotos do Scanner Facial', 'Photos du Scanner Facial'),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (images.isNotEmpty)
              IconButton(
                onPressed: () => _showUploadOptions(result.id, l10n),
                icon: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryPurpleLight),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (images.isEmpty)
          GestureDetector(
            onTap: () => _showUploadOptions(result.id, l10n),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primarySalmon.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: AppTheme.primaryPurpleLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.t('Nenhuma foto clínica adicionada', 'Aucune photo clinique ajoutée'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t(
                      'Carregue fotos de luz RGB, UV, Polarizada do scanner M7',
                      'Téléchargez des photos de lumière RGB, UV, Polarisée du scanner M7',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadOptions(result.id, l10n),
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.t('Carregar Imagem', 'Télécharger Image')),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (ctx, i) {
                final img = images[i];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => _viewImageFullscreen(img),
                          child: Image.network(
                            img.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: AppTheme.primarySalmon));
                            },
                          ),
                        ),
                        // Glass label overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Text(
                              img.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Delete Button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _confirmDeletePhoto(result.id, img.url, l10n),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showUploadOptions(String analysisId, AppL10n l10n) async {
    final labelController = TextEditingController();
    String selectedLabel = 'RGB / Luz Normal';
    final labels = [
      'RGB / Luz Normal',
      'Luz Polarizada (Textura)',
      'Luz UV (Manchas/Poros)',
      'Luz Vermelha (Vascular)',
      'Outro',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('Adicionar Foto do Scanner', 'Ajouter Photo du Scanner'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('Tipo de Filtro/Imagem:', 'Type de Filtre/Image :'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLabel,
                    dropdownColor: AppTheme.bgCard,
                    items: labels.map((l) {
                      return DropdownMenuItem(
                        value: l,
                        child: Text(l, style: const TextStyle(color: AppTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateSheet(() => selectedLabel = val);
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (selectedLabel == 'Outro') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.t('Nome Personalizado', 'Nom Personnalisé'),
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickAndUploadPhoto(
                            analysisId: analysisId,
                            label: selectedLabel == 'Outro' ? labelController.text.trim() : selectedLabel,
                            source: ImageSource.camera,
                            l10n: l10n,
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l10n.t('Tirar Foto', 'Prendre Photo')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndUploadPhoto(
                            analysisId: analysisId,
                            label: selectedLabel == 'Outro' ? labelController.text.trim() : selectedLabel,
                            source: ImageSource.gallery,
                            l10n: l10n,
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: Text(l10n.t('Galeria', 'Galerie')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto({
    required String analysisId,
    required String label,
    required ImageSource source,
    required AppL10n l10n,
  }) async {
    Navigator.pop(context); // close bottom sheet

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final bytes = await File(picked.path).readAsBytes();
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.uploadAnalysisPhoto(analysisId, label.isEmpty ? 'Scanner' : label, bytes);

      // Invalidate provider to refresh detail
      ref.invalidate(analysisDetailProvider(widget.analysisId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('Foto adicionada com sucesso!', 'Photo ajoutée avec succès !'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('Erro ao carregar foto', 'Erreur de chargement')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _confirmDeletePhoto(String analysisId, String url, AppL10n l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('Eliminar Foto?', 'Supprimer la Photo ?')),
        content: Text(l10n.t(
          'Tens a certeza que queres eliminar esta foto de scanner?',
          'Êtes-vous sûr de vouloir supprimer cette photo de scanner ?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _uploadingPhoto = true);
      try {
        final supabase = ref.read(supabaseServiceProvider);
        await supabase.deleteAnalysisPhoto(analysisId, url);

        ref.invalidate(analysisDetailProvider(widget.analysisId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('Foto eliminada!', 'Photo supprimée !'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _uploadingPhoto = false);
      }
    }
  }

  void _viewImageFullscreen(SpectrumImage img) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // InteractiveViewer with pinch/zoom
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  img.url,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    img.label,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, String> _parseSummary(String summaryText) {
    final sections = <String, String>{};
    final lines = summaryText.split('\n');
    String currentHeader = 'Geral';
    final currentContent = StringBuffer();

    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.startsWith('DIAGNÓSTICO GERAL DA PELE') || cleanLine.startsWith('DIAGNOSTICO GERAL DA PELE')) {
        if (currentContent.isNotEmpty) {
          sections[currentHeader] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentHeader = 'Diagnóstico';
      } else if (cleanLine.startsWith('ANÁLISE DETALHADA') ||
          cleanLine.startsWith('ANALYSE DETALHADA') ||
          cleanLine.startsWith('ANÁLISE DOS INDICADORES') ||
          cleanLine.startsWith('ANALISE DOS INDICADORES')) {
        if (currentContent.isNotEmpty) {
          sections[currentHeader] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentHeader = 'Indicadores';
      } else if (cleanLine.startsWith('RECOMENDAÇÕES DE ATIVOS') ||
          cleanLine.startsWith('RECOMENDACOES DE ATIVOS') ||
          cleanLine.startsWith('RECOMANDATIONS D\'ACTIFS') ||
          cleanLine.startsWith('RECOMANDATION D\'ACTIFS') ||
          cleanLine.startsWith('RECOMMANDATIONS D\'ACTIFS')) {
        if (currentContent.isNotEmpty) {
          sections[currentHeader] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentHeader = 'Ativos';
      } else if (cleanLine.startsWith('DIRETRIZES DE TRATAMENTO') ||
          cleanLine.startsWith('DIRETRIZES DO TRATAMENTO') ||
          cleanLine.startsWith('DIRECTIVES DE TRAITEMENT')) {
        if (currentContent.isNotEmpty) {
          sections[currentHeader] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentHeader = 'Tratamento';
      } else {
        if (cleanLine.isNotEmpty || currentContent.isNotEmpty) {
          currentContent.writeln(line);
        }
      }
    }

    if (currentContent.isNotEmpty) {
      sections[currentHeader] = currentContent.toString().trim();
    }

    // fallback if parser doesn't split anything
    if (sections.isEmpty || (sections.length == 1 && sections.containsKey('Geral'))) {
      return {'Diagnóstico': summaryText};
    }

    return sections;
  }

  Map<String, String> _parseRoutine(String routineText) {
    final routines = <String, String>{};
    final lines = routineText.split('\n');
    String currentRoutine = 'Manhã';
    final currentContent = StringBuffer();

    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.startsWith('RITUAL MATINAL') || cleanLine.startsWith('RITUAL DE MANHÃ') || cleanLine.startsWith('RITUEL MATINAL')) {
        if (currentContent.isNotEmpty) {
          routines[currentRoutine] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentRoutine = 'Manhã';
      } else if (cleanLine.startsWith('RITUAL NOTURNO') ||
          cleanLine.startsWith('RITUAL DE NOITE') ||
          cleanLine.startsWith('RITUEL DE NUIT') ||
          cleanLine.startsWith('RITUEL DE SOIR')) {
        if (currentContent.isNotEmpty) {
          routines[currentRoutine] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentRoutine = 'Noite';
      } else {
        if (cleanLine.isNotEmpty || currentContent.isNotEmpty) {
          currentContent.writeln(line);
        }
      }
    }

    if (currentContent.isNotEmpty) {
      routines[currentRoutine] = currentContent.toString().trim();
    }

    return routines;
  }

  Widget _buildProductsGrid(AnalysisResult result, List<Product> products) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(products.length, (i) {
            final product = products[i];
            final rec = result.recommendations
                .where((r) => r.productId == product.id)
                .firstOrNull;
            return SizedBox(
              width: cardWidth,
              child: ProductCard(
                product: product,
                matchReason: rec?.reason,
                priority: rec?.priority,
                onTap: () => context.push('/products/${product.id}'),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 + i * 80),
                  ),
            );
          }),
        );
      },
    );
  }
}
