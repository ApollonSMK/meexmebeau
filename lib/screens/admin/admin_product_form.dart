import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../models/product.dart';
import '../../widgets/gradient_button.dart';

class AdminProductForm extends ConsumerStatefulWidget {
  final String? productId;
  const AdminProductForm({super.key, this.productId});

  @override
  ConsumerState<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends ConsumerState<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _precoController = TextEditingController();
  final _precoEspecialController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _ingredientesController = TextEditingController();
  final _atributoController = TextEditingController();
  final _modoUsoController = TextEditingController();

  // Seletores
  String _categoria = AppConstants.productCategories.first;
  String? _genero;
  String? _condicaoPele;
  List<String> _indicadores = [];
  List<String> _publicoAlvo = [];
  List<String> _tiposPele = [];
  bool _ativo = true;
  bool _loading = false;
  bool _isEdit = false;

  // Imagem
  File? _imagemLocal;
  String? _imagemUrlExistente;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEdit = true;
      _carregarProduto();
    }
  }

  Future<void> _carregarProduto() async {
    final product =
        await ref.read(supabaseServiceProvider).getProduct(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _nomeController.text = product.name;
        _marcaController.text = product.brand ?? '';
        _precoController.text = product.price?.toStringAsFixed(2) ?? '';
        _precoEspecialController.text =
            product.specialPrice?.toStringAsFixed(2) ?? '';
        _websiteController.text = product.website ?? '';
        _descricaoController.text = product.description ?? '';
        _ingredientesController.text = product.ingredients ?? '';
        _atributoController.text = product.productAttribute ?? '';
        _modoUsoController.text = product.usageMethod ?? '';
        _categoria = product.category;
        _genero = product.applicableGender;
        _condicaoPele = product.applicationSkin;
        _indicadores = List.from(product.indicatorCorrelation);
        _publicoAlvo = List.from(product.applicableCrowd);
        _tiposPele = List.from(product.skinTypes);
        _ativo = product.isActive;
        _imagemUrlExistente = product.imageUrl;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _precoController.dispose();
    _precoEspecialController.dispose();
    _websiteController.dispose();
    _descricaoController.dispose();
    _ingredientesController.dispose();
    _atributoController.dispose();
    _modoUsoController.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Adicionar Foto',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                ),
                title: const Text(
                  'Tirar Foto',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Usa a câmara agora',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.accentPinkLight, size: 22),
                ),
                title: const Text(
                  'Escolher da Galeria',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Seleciona uma foto existente',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imagemLocal = File(picked.path));
    }
  }

  Future<String?> _uploadImagem() async {
    if (_imagemLocal == null) return _imagemUrlExistente;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await _imagemLocal!.readAsBytes();
      final ext = _imagemLocal!.path.split('.').last.toLowerCase();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_nomeController.text.trim().replaceAll(' ', '_')}.$ext';
      final service = ref.read(supabaseServiceProvider);
      return await service.uploadProductImage(fileName, bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar imagem: $e')),
        );
      }
      return _imagemUrlExistente;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Upload imagem primeiro (se houver)
      final imageUrl = await _uploadImagem();

      final product = Product(
        id: widget.productId ?? '',
        name: _nomeController.text.trim(),
        brand: _marcaController.text.trim().isEmpty
            ? null
            : _marcaController.text.trim(),
        price: _precoController.text.isNotEmpty
            ? double.tryParse(_precoController.text.replaceAll(',', '.'))
            : null,
        specialPrice: _precoEspecialController.text.isNotEmpty
            ? double.tryParse(
                _precoEspecialController.text.replaceAll(',', '.'))
            : null,
        imageUrl: imageUrl,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        description: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        category: _categoria,
        ingredients: _ingredientesController.text.trim().isEmpty
            ? null
            : _ingredientesController.text.trim(),
        productAttribute: _atributoController.text.trim().isEmpty
            ? null
            : _atributoController.text.trim(),
        usageMethod: _modoUsoController.text.trim().isEmpty
            ? null
            : _modoUsoController.text.trim(),
        applicableGender: _genero,
        applicationSkin: _condicaoPele,
        indicatorCorrelation: _indicadores,
        applicableCrowd: _publicoAlvo,
        skinTypes: _tiposPele,
        skinConcerns: const [],
        isActive: _ativo,
      );

      final service = ref.read(supabaseServiceProvider);
      if (_isEdit) {
        await service.updateProduct(widget.productId!, product);
      } else {
        await service.createProduct(product);
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Produto atualizado!' : 'Produto criado!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Produto' : 'Novo Produto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── FOTO DO PRODUTO ─────────────────────────────
            _sectionHeader('Foto do Produto', Icons.photo_camera_outlined),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 20),

            // ── INFORMAÇÕES BÁSICAS ──────────────────────────
            _sectionHeader('Informações Básicas', Icons.inventory_2_outlined),
            const SizedBox(height: 12),

            _campo('Marca', _marcaController),
            const SizedBox(height: 14),

            _campo(
              'Nome do Produto *',
              _nomeController,
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _campo(
                    'Preço (€) *',
                    _precoController,
                    teclado: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'Preço Especial (€)',
                    _precoEspecialController,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _campo('Website', _websiteController, teclado: TextInputType.url),
            const SizedBox(height: 20),

            // ── CATEGORIA ────────────────────────────────────
            _sectionHeader('Categoria', Icons.category_outlined),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Categoria *',
              value: _categoria,
              items: AppConstants.productCategories,
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 20),

            // ── GÉNERO ───────────────────────────────────────
            _sectionHeader('Género Aplicável *', Icons.people_outline),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.genderOptions.map((g) {
                final sel = _genero == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: sel,
                  onSelected: (_) => setState(() => _genero = g),
                  selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  checkmarkColor: AppTheme.primaryPurpleLight,
                  labelStyle: TextStyle(
                    color: sel
                        ? AppTheme.primaryPurpleLight
                        : AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── CONDIÇÃO DE PELE ─────────────────────────────
            _sectionHeader('Condição de Pele Aplicável *',
                Icons.face_retouching_natural),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skinConditionOptions.map((s) {
                final sel = _condicaoPele == s;
                final cor = _corCondicao(s);
                return ChoiceChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (_) => setState(() => _condicaoPele = s),
                  selectedColor: cor.withValues(alpha: 0.25),
                  checkmarkColor: cor,
                  labelStyle: TextStyle(
                    color: sel ? cor : AppTheme.textSecondary,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── INDICADORES ──────────────────────────────────
            _sectionHeader(
                'Indicadores Correlacionados *', Icons.bar_chart_rounded),
            const SizedBox(height: 4),
            const Text(
              'Seleciona os parâmetros medidos pelo dispositivo',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.indicatorOptions.map((ind) {
                final sel = _indicadores.contains(ind);
                return FilterChip(
                  label: Text(ind),
                  selected: sel,
                  onSelected: (s) => setState(
                      () => s ? _indicadores.add(ind) : _indicadores.remove(ind)),
                  selectedColor: AppTheme.accentPink.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.accentPinkLight,
                  labelStyle: TextStyle(
                    color:
                        sel ? AppTheme.accentPinkLight : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── PÚBLICO-ALVO ─────────────────────────────────
            _sectionHeader('Público-Alvo *', Icons.groups_outlined),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.crowdOptions.map((crowd) {
                final sel = _publicoAlvo.contains(crowd);
                return FilterChip(
                  label: Text(crowd),
                  selected: sel,
                  onSelected: (s) => setState(() =>
                      s ? _publicoAlvo.add(crowd) : _publicoAlvo.remove(crowd)),
                  selectedColor:
                      AppTheme.primaryPurple.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.primaryPurpleLight,
                  labelStyle: TextStyle(
                    color: sel
                        ? AppTheme.primaryPurpleLight
                        : AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── DETALHES ─────────────────────────────────────
            _sectionHeader('Detalhes do Produto', Icons.description_outlined),
            const SizedBox(height: 12),

            _campo('Atributo do Produto', _atributoController),
            const SizedBox(height: 14),

            // Modo de uso com contador
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modo de Utilização (máx. 40 caracteres)',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _modoUsoController,
                  maxLength: 40,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(counterText: ''),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ValueListenableBuilder(
                    valueListenable: _modoUsoController,
                    builder: (ctx, val, child) => Text(
                      '${val.text.length}/40',
                      style: TextStyle(
                        color: val.text.length > 40
                            ? AppTheme.error
                            : AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _campo('Descrição', _descricaoController, maxLines: 3),
            const SizedBox(height: 14),

            _campo('Ingredientes', _ingredientesController, maxLines: 3),
            const SizedBox(height: 20),

            // ── TIPOS DE PELE (IA) ───────────────────────────
            _sectionHeader(
                'Tipos de Pele (para IA)', Icons.spa_outlined),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skinTypes
                  .map((t) => FilterChip(
                        label: Text(t),
                        selected: _tiposPele.contains(t),
                        onSelected: (s) => setState(() =>
                            s ? _tiposPele.add(t) : _tiposPele.remove(t)),
                        selectedColor:
                            AppTheme.primaryPurple.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.primaryPurpleLight,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // ── ESTADO ───────────────────────────────────────
            _sectionHeader('Estado', Icons.toggle_on_outlined),
            SwitchListTile(
              value: _ativo,
              title: const Text(
                'Produto ativo',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: const Text(
                'Produtos inativos não aparecem no catálogo',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              activeThumbColor: AppTheme.success,
              onChanged: (v) => setState(() => _ativo = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 28),

            GradientButton(
              text: _isEdit ? 'Guardar Alterações' : 'Criar Produto',
              icon: Icons.save,
              isLoading: _loading || _uploadingImage,
              onPressed: _guardar,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Widget de upload de imagem ────────────────────────────────

  Widget _buildImagePicker() {
    final hasImage = _imagemLocal != null || _imagemUrlExistente != null;

    return GestureDetector(
      onTap: _escolherImagem,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage
                ? AppTheme.primaryPurple.withValues(alpha: 0.4)
                : AppTheme.primarySalmon.withValues(alpha: 0.15),
            width: hasImage ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: _imagemLocal != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imagemLocal!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Alterar',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _imagemUrlExistente != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(_imagemUrlExistente!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('Alterar',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Toca para adicionar foto',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'JPG ou PNG • Tamanho recomendado: 551×421',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Color _corCondicao(String cond) {
    switch (cond) {
      case 'Boa':
        return const Color(0xFF4CAF50);
      case 'Média':
        return const Color(0xFF8BC34A);
      case 'Geral':
        return const Color(0xFFFFC107);
      case 'Fraca':
        return const Color(0xFFFF9800);
      case 'Grave':
        return const Color(0xFFF44336);
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _sectionHeader(String titulo, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryPurpleLight),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: const TextStyle(
              color: AppTheme.primaryPurpleLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? teclado,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: teclado,
          validator: validator,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          // ignore: deprecated_member_use
          value: value,
          dropdownColor: AppTheme.bgElevated,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: items
              .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.toString())))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
