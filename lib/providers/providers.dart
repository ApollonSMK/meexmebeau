import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/openai_service.dart';
import '../services/share_intent_service.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';
import '../config/l10n.dart';

// ============ CORE SERVICES ============

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

// ============ PRODUCTS ============

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  return service.getProducts();
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  return service.getAllProducts();
});

// ============ ANALYSES ============

final analysesProvider = FutureProvider<List<AnalysisResult>>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  return service.getAnalyses();
});

// ============ SHARED DATA STATE ============

final sharedDataProvider = NotifierProvider<SharedDataNotifier, SharedData?>(
  SharedDataNotifier.new,
);

class SharedDataNotifier extends Notifier<SharedData?> {
  @override
  SharedData? build() => null;

  void set(SharedData? data) {
    state = data;
  }

  void clear() {
    state = null;
  }
}

// ============ ANALYSIS STATE ============

enum AnalysisStatus { idle, loading, success, error }

class AnalysisState {
  final AnalysisStatus status;
  final AnalysisResult? result;
  final String? error;
  final List<Product> recommendedProducts;

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.result,
    this.error,
    this.recommendedProducts = const [],
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    AnalysisResult? result,
    String? error,
    List<Product>? recommendedProducts,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
    );
  }
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  Future<void> analyzeRapport(String rapportText) async {
    state = state.copyWith(status: AnalysisStatus.loading);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final openAIService = ref.read(openAIServiceProvider);

      // 1. Get available products
      final products = await supabaseService.getProducts();

      if (products.isEmpty) {
        state = state.copyWith(
          status: AnalysisStatus.error,
          error:
              'Nenhum produto encontrado no catálogo. '
              'Adicione produtos na secção Admin primeiro.',
        );
        return;
      }

      final lang = ref.read(languageProvider);
      final langCode = lang == AppLanguage.pt ? 'pt' : 'fr';

      // 2. Send to OpenAI for analysis
      final result = await openAIService.analyzeRapport(
        rapportText: rapportText,
        availableProducts: products,
        targetLanguage: langCode,
      );

      // 3. Fetch recommended products
      final recommendedIds = result.recommendations
          .map((r) => r.productId)
          .toList();
      final recommendedProducts = await supabaseService.getProductsByIds(
        recommendedIds,
      );

      // 4. Save to database
      final savedResult = await supabaseService.saveAnalysis(result);

      // 5. Refresh history
      ref.invalidate(analysesProvider);

      state = state.copyWith(
        status: AnalysisStatus.success,
        result: savedResult,
        recommendedProducts: recommendedProducts,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.error,
        error: 'Erro na análise: $e',
      );
    }
  }

  Future<void> analyzeImage(String base64Image) async {
    state = state.copyWith(status: AnalysisStatus.loading);

    try {
      final openAIService = ref.read(openAIServiceProvider);

      // 1. Extract text from image using GPT Vision
      final extractedText = await openAIService.extractTextFromImage(
        base64Image,
      );

      // 2. Run the analysis with extracted text
      await analyzeRapport(extractedText);
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.error,
        error: 'Erro ao processar imagem: $e',
      );
    }
  }

  Future<void> analyzePdf(String filePath) async {
    state = state.copyWith(status: AnalysisStatus.loading);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final openAIService = ref.read(openAIServiceProvider);

      // 1. Get available products
      final products = await supabaseService.getProducts();

      final lang = ref.read(languageProvider);
      final langCode = lang == AppLanguage.pt ? 'pt' : 'fr';

      // 2. Send PDF directly to GPT-4o (images + text + charts)
      final result = await openAIService.analyzePdfDirect(
        pdfFilePath: filePath,
        availableProducts: products,
        targetLanguage: langCode,
      );

      // 3. Save analysis
      final savedResult = await supabaseService.saveAnalysis(result);

      // 4. Refresh history
      ref.invalidate(analysesProvider);

      // 5. Get recommended products
      final recommendedProducts = products.where((p) {
        return savedResult.recommendations.any((r) => r.productId == p.id);
      }).toList();

      state = state.copyWith(
        status: AnalysisStatus.success,
        result: savedResult,
        recommendedProducts: recommendedProducts,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.error,
        error: 'Erro ao processar PDF: $e',
      );
    }
  }

  void reset() {
    state = const AnalysisState();
  }
}

final analysisNotifierProvider =
    NotifierProvider<AnalysisNotifier, AnalysisState>(AnalysisNotifier.new);

// ============ AUTH STATE ============

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  return service.isAdmin();
});

// ============ ADMIN STATS ============

class AdminStats {
  final int productCount;
  final int analysisCount;

  AdminStats({required this.productCount, required this.analysisCount});
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  final products = await ref.watch(allProductsProvider.future);
  final analysisCount = await service.getAnalysisCount();
  return AdminStats(productCount: products.length, analysisCount: analysisCount);
});
