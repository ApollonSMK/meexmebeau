import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';
import 'pdf_service.dart';

class OpenAIService {
  OpenAIService() {
    OpenAI.apiKey = AppConstants.openAiApiKey;
  }

  /// System prompt helper for the skin analysis AI
  static String _getSystemPrompt(String targetLanguage) {
    final langLabel = targetLanguage == 'fr' ? 'Francês (French/Français)' : 'Português de Portugal (PT-PT/Portuguese)';
    final langInstructions = targetLanguage == 'fr'
        ? 'Você deve responder e escrever obrigatoriamente em Francês (Français) sofisticado, refinado, elegante e com terminologia clínica altamente profissional (clinical-grade French). O relatório final deve ser completamente redigido em Francês. Mesmo que o rapport de entrada (PDF ou texto) esteja escrito em Português, Inglês ou outro idioma, traduza as conclusões e escreva todas as respostas textuais em Francês.'
        : 'Você deve responder e escrever obrigatoriamente em Português de Portugal (PT-PT) sofisticado, elegante e profissional. O relatório final deve ser completamente redigido em Português de Portugal. Mesmo que o rapport de entrada (PDF ou texto) esteja escrito em Francês ou outro idioma, escreva todas as respostas textuais em Português.';

    return '''
Você é um médico dermatologista estético altamente conceituado e especialista em cosmetologia avançada, com vasta experiência em analisar relatórios do scanner facial M7 (e equipamentos similares de imagem multiespectral).

Sua missão é realizar uma análise de pele extremamente detalhada, clínica, rigorosa e personalizada, fornecendo ao cliente um diagnóstico profundo e um plano de tratamento de prestígio (tipo premium/estúdio de estética de luxo).

Ao receber os dados de análise (que incluem scores, métricas e dados de imagem) e a lista de produtos disponíveis no catálogo:

1. DIAGNÓSTICO PROFUNDO & RIGOROSO:
   - Analise minuciosamente todas as informações clínicas e scores de pele fornecidos.
   - Atribua scores precisos de 0 a 10 (onde 10 representa uma pele perfeita, sem necessidade de intervenção) para cada um dos seguintes 8 indicadores:
     * hydration (hidratação da epiderme e barreira cutânea)
     * wrinkles (profundidade das rugas, linhas finas e expressão)
     * pores (dilatação, visibilidade e obstrução dos poros)
     * spots (manchas pigmentares, hiperpigmentação solar, melasma)
     * texture (suavidade, queratinização e uniformidade do relevo cutâneo)
     * acne (presença de lesões inflamatórias, pápulas, pústulas ou comedões)
     * elasticity (firmeza, tônus cutâneo e sustentação)
     * dark_circles (olheiras vasculares, pigmentares ou estruturais)
   - Determine com precisão científica o Tipo de Pele (Normal, Oleosa, Seca, Mista ou Sensível).
   - Identifique e liste as Preocupações Críticas da Pele (concerns) como termos clínicos profissionais.

2. ELABORAÇÃO DO RESUMO CLÍNICO (summary) - DEVE SER ALGO EXCECIONAL E ULTRA-COMPLETO:
   O campo "summary" deve ser um relatório clínico completo, rico e sofisticado, estruturado com quebras de linha claras (usando \\n\\n) e títulos em maiúsculas. Deve conter pelo menos 3 a 4 parágrafos robustos cobrindo:
   - DIAGNÓSTICO GERAL DA PELE: Uma introdução clínica formal sobre a saúde geral da pele do cliente, cruzando a sua idade cronológica com a idade biológica da pele.
   - ANÁLISE DETALHADA DOS PRINCIPAIS INDICADORES: Explicação fisiológica aprofundada dos scores mais baixos. Por exemplo, relacionar manchas com danos UV e atividade melanocítica; relacionar acne/poros com hiperatividade sebácea; detalhar a desidratação e o comprometimento da barreira lipídica.
   - RECOMENDAÇÕES DE ATIVOS & SINERGIA COSMÉTICA: Explicar detalhadamente como os ingredientes ativos dos produtos recomendados (como Ácido Hialurónico, Vitamina C, Retinol, Niacinamida, etc.) vão atuar sinergicamente nas células da pele para reverter os danos identificados.
   - DIRETRIZES DE TRATAMENTO PROFISSIONAL: Explicar a importância de aliar o protocolo clínico profissional (Soins Cliniques) com a manutenção rigorosa em casa (Soins Domiciles) para potenciar e prolongar os resultados.

3. RECOMENDAÇÕES DE PRODUTOS PREMIUM:
   - Selecione estrategicamente os melhores produtos do catálogo que correspondam exatamente às necessidades diagnosticadas do cliente.
   - Use APENAS os IDs de produtos fornecidos na lista.
   - Classifique as recomendações por prioridade de impacto (1 = prioridade máxima).
   - Equilibre a recomendação entre:
     * [Rotina Casa / Público]: Cuidados diários que o cliente fará em casa.
     * [Tratamento Interno / Clínica]: Protocolos intensivos que só podem ser aplicados em consultório pelo profissional.
   - No campo "reason" de cada produto, escreva uma explicação clínica detalhada e sofisticada, justificando o porquê de aquele produto em particular ser vital para a regeneração da pele do cliente.

4. PROTOCOLO DE ROTINA DE CASA DETALHADO (routine_suggestion):
   O campo "routine_suggestion" deve ser um guia passo a passo luxuoso e extremamente detalhado para o ritual diário do cliente, separado por:
   - RITUAL MATINAL (MANHÃ): Passos claros e ordenados de limpeza, tonificação, sérum de tratamento ativo, hidratação e proteção solar de prestígio, com conselhos de aplicação profissional (ex: massagem ascendente, pressões suaves).
   - RITUAL NOTURNO (NOITE): Passos claros e ordenados de dupla limpeza, esfoliação/máscara semanal (se recomendado), tratamento reparador regenerador (com retinol ou ácidos ativos) e creme de nutrição profunda, especificando a frequência de uso e técnicas de relaxamento facial.

REGRAS DE FORMATAÇÃO E IDIOMA CRÍTICAS:
- IDIOMA OBRIGATÓRIO DO RELATÓRIO: $langInstructions
- Todos os campos textuais livres (ex: 'summary', 'concerns', 'routine_suggestion', e o campo 'reason' em 'recommendations') devem ser escritos inteiramente no idioma indicado ($langLabel).
- O campo 'skin_type' DEVE ser sempre respondido com um dos valores exatos em Português: 'Normal', 'Oleosa', 'Seca', 'Mista' ou 'Sensível', para manter a consistência com a base de dados da aplicação móvel.
- NÃO use nenhuma formatação markdown (NÃO use asteriscos **, cardinais ##, marcadores de lista markdown, etc.). Use apenas texto simples. Para estruturar cabeçalhos, use letras maiúsculas (ex: RITUAL MATINAL:) e use quebras de linha com \\n\\n para separar secções.
- Responda EXCLUSIVAMENTE em formato JSON perfeitamente válido com a estrutura indicada abaixo.

Estrutura JSON esperada:
{
  "client_name": "Nome da pessoa (se disponível)",
  "client_age": 42,
  "skin_age": 42,
  "skin_type": "Normal|Oleosa|Seca|Mista|Sensível",
  "skin_scores": {
    "hydration": 0-10,
    "wrinkles": 0-10,
    "pores": 0-10,
    "spots": 0-10,
    "texture": 0-10,
    "acne": 0-10,
    "elasticity": 0-10,
    "dark_circles": 0-10
  },
  "concerns": ["Hiperpigmentação Epidérmica", "Desidratação Cutânea", "Perda de Firmeza"],
  "summary": "DIAGNÓSTICO GERAL DA PELE:\\n\\n[Texto longo e ultra-completo]\\n\\nANÁLISE DETALHADA DOS INDICADORES:\\n\\n[Texto longo e ultra-completo]\\n\\nRECOMENDAÇÕES DE ATIVOS & SINERGIA COSMÉTICA:\\n\\n[Texto longo e ultra-completo]\\n\\nDIRETRIZES DE TRATAMENTO PROFISSIONAL:\\n\\n[Texto longo e ultra-completo]",
  "recommendations": [
    {
      "product_id": "uuid-do-produto",
      "reason": "Explicação clínica detalhada e sofisticada de por que este produto específico é indispensável.",
      "priority": 1
    }
  ],
  "routine_suggestion": "RITUAL MATINAL (MANHÃ):\\n\\n1. Limpeza...\\n2. Tonificação...\\n\\nRITUAL NOTURNO (NOITE):\\n\\n1. Dupla Limpeza...\\n2. Tratamento reparador..."
}
''';
  }

  /// Analyze a rapport and recommend products
  Future<AnalysisResult> analyzeRapport({
    required String rapportText,
    required List<Product> availableProducts,
    String targetLanguage = 'fr',
  }) async {
    // Build the product catalog for the prompt
    final productCatalog = availableProducts
        .map((p) => p.toPromptSummary())
        .join('\n');

    final userMessage =
        '''
RAPPORT DE ANÁLISE FACIAL:
---
$rapportText
---

CATÁLOGO DE PRODUTOS DISPONÍVEIS:
---
$productCatalog
---

Analise o rapport acima e recomende os melhores produtos do catálogo para este perfil de pele. Responda em JSON.
''';

    final chatCompletion = await OpenAI.instance.chat.create(
      model: AppConstants.openAiModel,
      responseFormat: {"type": "json_object"},
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              _getSystemPrompt(targetLanguage),
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
          ],
        ),
      ],
      temperature: 0.3,
      maxTokens: 2000,
    );

    final responseContent =
        chatCompletion.choices.first.message.content?.first.text ?? '{}';

    // Parse the JSON response
    final Map<String, dynamic> gptJson = jsonDecode(responseContent);

    return AnalysisResult.fromGptResponse(rapportText, gptJson);
  }

  /// Analyze a PDF rapport directly — extracts text locally first, and then sends both
  /// the extracted text and the PDF base64 file to GPT-4o for a high-quality clinical analysis
  Future<AnalysisResult> analyzePdfDirect({
    required String pdfFilePath,
    required List<Product> availableProducts,
    String targetLanguage = 'fr',
  }) async {
    // 1. Extract text locally using Syncfusion PDF
    String extractedText = '';
    try {
      extractedText = await PdfService.extractTextFromPdf(pdfFilePath);
    } catch (e) {
      debugPrint('Local PDF text extraction failed: $e');
    }

    final file = File(pdfFilePath);
    final bytes = await file.readAsBytes();
    final base64Pdf = base64Encode(bytes);

    final productCatalog = availableProducts
        .map((p) => p.toPromptSummary())
        .join('\n');

    final userTextMessage = '''
O ficheiro PDF em anexo é um rapport de análise facial do scanner M7.

TEXTO EXTRAÍDO DO PDF:
---
$extractedText
---

CATÁLOGO DE PRODUTOS DISPONÍVEIS:
---
$productCatalog
---

Analise o rapport completo de forma profunda e profissional (incluindo imagens, gráficos e o texto extraído fornecido acima) e recomende os melhores produtos. Responda em JSON seguindo rigorosamente as instruções do sistema.
''';

    // Use HTTP directly to support file input (dart_openai doesn't support it)
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConstants.openAiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConstants.openAiModel,
        'response_format': {'type': 'json_object'},
        'temperature': 0.3,
        'max_tokens': 2500,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(targetLanguage),
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'file',
                'file': {
                  'filename': 'rapport_m7.pdf',
                  'file_data': 'data:application/pdf;base64,$base64Pdf',
                },
              },
              {
                'type': 'text',
                'text': userTextMessage,
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} — ${response.body}');
    }

    final responseJson = jsonDecode(response.body);
    final content = responseJson['choices'][0]['message']['content'] ?? '{}';
    final Map<String, dynamic> gptJson = jsonDecode(content);

    return AnalysisResult.fromGptResponse('PDF Rapport: $pdfFilePath', gptJson);
  }

  /// Analyze a product image and return structured fields in French (FR)
  Future<Map<String, dynamic>> analyzeProductImage(String base64Image) async {
    final systemPrompt = '''
You are an expert aesthetic product analyzer. 
Analyze the provided product image (bottle, tube, packaging, or label) and extract its details.
ALL TEXT FIELDS (name, brand, description, ingredients, product_attribute, usage_method) MUST BE WRITTEN IN FRENCH (FR), even if the packaging is in another language!

Return EXCLUSIVELY a valid JSON object with the following structure:
{
  "name": "Product name in French (clear, without brand prefix if redundant)",
  "brand": "Brand name",
  "description": "A beautiful and concise commercial description of the product in French (approx 2-3 sentences)",
  "category": "One of these EXACT Portuguese categories based on the product type: Limpeza|Tónico|Sérum|Hidratante|Protetor Solar|Esfoliante|Máscara|Contorno de Olhos|Tratamento|Suplemento",
  "ingredients": "Key ingredients or full list, in French or as written on package",
  "product_attribute": "Key product benefits or attributes in French (e.g. Anti-âge, Hydratation intense, Éclat)",
  "usage_method": "How to use in French (extremely concise, MAXIMUM 40 characters!)",
  "applicable_gender": "One of: 01-Masculino|02-Feminino|03-Unissexo",
  "application_skin": "One of: Boa|Média|Geral|Fraca|Grave (Choose 'Geral' as a default if not specific)",
  "indicator_correlation": ["Choose relevant indicators from this list: Poros|Porfirina|Acne|Sebo|Poro Entupido|Pigmento Epidérmico|Pigmento Dérmico|Área Castanha|Dano UV|Melasma|Área Sensível|Vasos Capilares|Térmica|Borbulha|Ruga|Textura|Hidratação|Colágenio"],
  "applicable_crowd": ["Choose relevant age groups from this list: 01-Jovem|02-Adulto Jovem|03-Meia-Idade|04-Sénior|05-Todos"],
  "skin_types": ["Choose matching skin types from this list: Normal|Oleosa|Seca|Mista|Sensível"]
}

Important Rules:
1. "usage_method" must be under 40 characters including spaces.
2. "category", "applicable_gender", "application_skin", "indicator_correlation", "applicable_crowd", and "skin_types" must use the exact values listed above (which are in Portuguese to match the database).
3. All free text fields must be returned in professional French.
4. Do not include markdown formatting or wrapping around JSON, return ONLY the raw JSON string.
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConstants.openAiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} — ${response.body}');
    }

    final responseJson = jsonDecode(response.body);
    final responseContent = responseJson['choices'][0]['message']['content'] ?? '{}';

    return jsonDecode(responseContent) as Map<String, dynamic>;
  }

  /// Simple text extraction from image (if rapport is an image)
  Future<String> extractTextFromImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConstants.openAiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'temperature': 0.3,
        'max_tokens': 1500,
        'messages': [
          {
            'role': 'system',
            'content': 'Extraia TODO o texto visível nesta imagem de rapport/relatório de análise facial. '
                'Inclua todos os números, scores, percentagens e categorias. '
                'Formate de forma estruturada e legível.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} — ${response.body}');
    }

    final responseJson = jsonDecode(response.body);
    return responseJson['choices'][0]['message']['content'] ?? 'Não foi possível extrair texto da imagem.';
  }
}

