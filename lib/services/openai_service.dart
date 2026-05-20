import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

class OpenAIService {
  OpenAIService() {
    OpenAI.apiKey = AppConstants.openAiApiKey;
  }

  /// System prompt for the skin analysis AI
  static const String _systemPrompt = '''
Você é um especialista em dermatologia estética e skincare profissional com anos de experiência em análise facial e recomendação de produtos.

Recebe um rapport de análise facial (possivelmente do scanner M7 ou equipamento similar) e uma lista de produtos disponíveis no catálogo.

Sua tarefa:
1. Analisar cuidadosamente o rapport e identificar todas as condições da pele
2. Atribuir scores de 0 a 10 (onde 10 = excelente/sem problemas) para:
   - hydration (hidratação)
   - wrinkles (rugas e linhas finas)
   - pores (tamanho e visibilidade dos poros)
   - spots (manchas, hiperpigmentação)
   - texture (textura e suavidade)
   - acne (presença de acne ou comedões)
   - elasticity (elasticidade e firmeza)
   - dark_circles (olheiras)
3. Identificar o tipo de pele: Normal, Oleosa, Seca, Mista, Sensível
4. Listar as principais preocupações
5. Recomendar os melhores produtos DA LISTA FORNECIDA (usando o ID exato).
   ATENÇÃO AOS TIPOS: 
   - [Rotina Casa / Público]: Produtos para a rotina diária do cliente.
   - [Tratamento Interno / Clínica]: Produtos/Protocolos apenas para uso na clínica pelo profissional.
   Recomende ambos os tipos se for adequado ao caso!
6. Explicar POR QUE cada produto é recomendado para este perfil
7. Sugerir uma rotina de skincare (rotina de casa) com os produtos recomendados

IMPORTANTE: 
- Use APENAS os IDs dos produtos fornecidos na lista
- Ordene recomendações por prioridade (1 = mais importante)
- Se o rapport não tiver informação suficiente para algum score, estime com base nos dados disponíveis
- Responda SEMPRE em Português de Portugal
- NÃO use formatação markdown (sem **, ##, etc). Use texto simples e quebras de linha com \n

Responda EXCLUSIVAMENTE em JSON válido com esta estrutura:
{
  "client_name": "Nome da pessoa (se disponível no rapport)",
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
  "concerns": ["preocupação1", "preocupação2"],
  "summary": "Resumo detalhado da análise da pele",
  "recommendations": [
    {
      "product_id": "uuid-do-produto",
      "reason": "Explicação de por que este produto é ideal para este perfil",
      "priority": 1
    }
  ],
  "routine_suggestion": "Sugestão detalhada de rotina matinal e noturna (focada nos produtos de Rotina Casa)"
}
''';

  /// Analyze a rapport and recommend products
  Future<AnalysisResult> analyzeRapport({
    required String rapportText,
    required List<Product> availableProducts,
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
              _systemPrompt,
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

  /// Analyze a PDF rapport directly — sends the full PDF to GPT-4o
  /// so it can see images, charts, graphs and text
  Future<AnalysisResult> analyzePdfDirect({
    required String pdfFilePath,
    required List<Product> availableProducts,
  }) async {
    final file = File(pdfFilePath);
    final bytes = await file.readAsBytes();
    final base64Pdf = base64Encode(bytes);

    final productCatalog = availableProducts
        .map((p) => p.toPromptSummary())
        .join('\n');

    final userTextMessage = '''
O ficheiro PDF em anexo é um rapport de análise facial do scanner M7.
Analise TODAS as imagens, gráficos, scores e texto do rapport.

CATÁLOGO DE PRODUTOS DISPONÍVEIS:
---
$productCatalog
---

Analise o rapport completo (incluindo imagens e gráficos) e recomende os melhores produtos. Responda em JSON.
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
            'content': _systemPrompt,
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

    final chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-4o',
      responseFormat: {"type": "json_object"},
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
              'data:image/jpeg;base64,$base64Image',
            ),
          ],
        ),
      ],
      temperature: 0.2,
      maxTokens: 1000,
    );

    final responseContent =
        chatCompletion.choices.first.message.content?.first.text ?? '{}';

    return jsonDecode(responseContent) as Map<String, dynamic>;
  }

  /// Simple text extraction from image (if rapport is an image)
  Future<String> extractTextFromImage(String base64Image) async {
    final chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-4o',
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'Extraia TODO o texto visível nesta imagem de rapport/relatório de análise facial. '
              'Inclua todos os números, scores, percentagens e categorias. '
              'Formate de forma estruturada e legível.',
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
              'data:image/jpeg;base64,$base64Image',
            ),
          ],
        ),
      ],
      maxTokens: 1500,
    );

    return chatCompletion.choices.first.message.content?.first.text ??
        'Não foi possível extrair texto da imagem.';
  }
}

