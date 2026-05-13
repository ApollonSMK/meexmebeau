import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../config/theme.dart';
import '../providers/providers.dart';
import '../services/update_service.dart';
import '../widgets/gradient_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSharedData();
      _checkForUpdate();
    });
  }

  void _handleSharedData() {
    final sharedData = ref.read(sharedDataProvider);
    if (sharedData != null) {
      context.push('/analysis');
    }
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && mounted) {
      _showUpdateSheet(info);
    }
  }

  void _showUpdateSheet(UpdateInfo info) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UpdateBottomSheet(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyses = ref.watch(analysesProvider);
    final sharedData = ref.watch(sharedDataProvider);

    if (sharedData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/analysis');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildHeroCard(),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Análises Recentes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            analyses.when(
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyState(),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: _buildAnalysisCard(list[i]),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 500 + i * 100),
                            ),
                        childCount: list.length.clamp(0, 5),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildEmptyState(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GradientButton(
                  text: 'Enviar Rapport PDF',
                  icon: Icons.picture_as_pdf,
                  onPressed: _pickAndAnalyzePdf,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEBeauty IA',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Análise Facial Inteligente',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
          IconButton(
            onPressed: () => context.push('/admin'),
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.15),
            AppTheme.accentPink.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
            child: const Icon(
              Icons.face_retouching_natural,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Como funciona?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _step('1', 'Abre o rapport no app M7'),
          _step('2', 'Clica em "Compartilhar com"'),
          _step('3', 'Seleciona MEBeauty IA'),
          _step('4', 'A IA analisa e recomenda produtos'),
        ],
      ),
    );
  }

  Widget _step(String n, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  n,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              Icons.history,
              'Histórico',
              'Análises anteriores',
              () => context.push('/history'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard(
              Icons.spa_outlined,
              'Produtos',
              'Ver catálogo',
              () => context.push('/products'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String label,
    String sub,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryPurpleLight, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'Nenhuma análise ainda',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Partilha um rapport do M7 para começar',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(dynamic analysis) {
    return GestureDetector(
      onTap: () => context.push('/analysis/result/${analysis.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primarySalmon.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.face, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pele ${analysis.skinType}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${analysis.recommendations.length} produtos recomendados',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _pickAndAnalyzePdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      ref.read(analysisNotifierProvider.notifier).analyzePdf(filePath);
      if (mounted) context.push('/analysis');
    }
  }
}

// ── Bottom Sheet de Atualização ────────────────────────────────

class _UpdateBottomSheet extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateBottomSheet({required this.info});

  @override
  State<_UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<_UpdateBottomSheet> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  String? _apkPath;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _error = null;
    });

    final path = await UpdateService.downloadApk(
      widget.info.apkDownloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    if (path == null) {
      setState(() {
        _downloading = false;
        _error = 'Erro ao descarregar. Tenta novamente.';
      });
      return;
    }

    setState(() {
      _apkPath = path;
      _downloading = false;
    });

    // Tenta instalar automaticamente após download
    _install();
  }

  Future<void> _install() async {
    if (_apkPath == null) return;

    final file = File(_apkPath!);
    if (!await file.exists()) {
      if (mounted) {
        setState(() {
          _error = 'Ficheiro não encontrado. Descarrega de novo.';
          _apkPath = null;
        });
      }
      return;
    }

    final error = await UpdateService.installApk(_apkPath!);
    if (error != null && mounted) {
      setState(() {
        _error = 'Não foi possível instalar automaticamente.\n'
            'Verifica em Definições > Apps > MEBeauty IA > '
            'Instalar apps desconhecidas e ativa a opção.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ícone + título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.system_update, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova versão disponível!',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'v${widget.info.currentVersion} → v${widget.info.latestVersion}',
                      style: const TextStyle(
                          color: AppTheme.primaryPurpleLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notas de release
          if (widget.info.releaseNotes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.info.releaseNotes,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Progresso de download
          if (_downloading) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'A descarregar...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: AppTheme.primaryPurpleLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor:
                        AppTheme.primaryPurple.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryPurpleLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Erro
          if (_error != null) ...[
            Text(_error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            const SizedBox(height: 12),
          ],

          // Botões
          if (_apkPath != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.install_mobile),
                label: const Text('Instalar Agora'),
                onPressed: () => OpenFile.open(_apkPath!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (!_downloading) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(
                          color:
                              AppTheme.textMuted.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mais tarde'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    text: 'Atualizar',
                    icon: Icons.download_rounded,
                    onPressed: _download,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
