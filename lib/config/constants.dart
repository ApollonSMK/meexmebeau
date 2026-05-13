import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get openAiModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o';
  static String get githubRepo => dotenv.env['GITHUB_REPO'] ?? 'ApollonSMK/meexmebeau';

  static const String appName = 'MEBeauty IA';
  static const String appVersion = '1.0.0';

  // Skin concern categories (legacy — used in AI analysis)
  static const List<String> skinConcerns = [
    'Acne',
    'Rugas',
    'Manchas',
    'Poros Dilatados',
    'Desidratação',
    'Oleosidade',
    'Flacidez',
    'Olheiras',
    'Rosácea',
    'Textura Irregular',
  ];

  // Skin types (legacy — used in AI analysis)
  static const List<String> skinTypes = [
    'Normal',
    'Oleosa',
    'Seca',
    'Mista',
    'Sensível',
  ];

  // Product categories
  static const List<String> productCategories = [
    'Limpeza',
    'Tónico',
    'Sérum',
    'Hidratante',
    'Protetor Solar',
    'Esfoliante',
    'Máscara',
    'Contorno de Olhos',
    'Tratamento',
    'Suplemento',
  ];

  // ── Device-specific fields ──────────────────────────────────

  /// Opções de género aplicável
  static const List<String> genderOptions = [
    '01-Masculino',
    '02-Feminino',
    '03-Unissexo',
  ];

  /// Classificação da condição de pele
  static const List<String> skinConditionOptions = [
    'Boa',
    'Média',
    'Geral',
    'Fraca',
    'Grave',
  ];

  /// Indicadores correlacionados — parâmetros medidos pelo dispositivo
  static const List<String> indicatorOptions = [
    'Poros',
    'Porfirina',
    'Acne',
    'Sebo',
    'Poro Entupido',
    'Pigmento Epidérmico',
    'Pigmento Dérmico',
    'Área Castanha',
    'Dano UV',
    'Melasma',
    'Área Sensível',
    'Vasos Capilares',
    'Térmica',
    'Borbulha',
    'Ruga',
    'Textura',
    'Hidratação',
    'Colágenio',
  ];

  /// Público-alvo (faixas etárias)
  static const List<String> crowdOptions = [
    '01-Jovem',
    '02-Adulto Jovem',
    '03-Meia-Idade',
    '04-Sénior',
    '05-Todos',
  ];
}
