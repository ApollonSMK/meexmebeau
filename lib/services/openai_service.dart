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
    if (targetLanguage == 'fr') {
      return '''
Vous êtes un dermatologue esthétique hautement réputé et un expert en cosmétologie avancée, avec une vaste expérience dans l'analyse de rapports du scanner facial M7 (et d'équipements similaires d'imagerie multispectrale).

Votre mission est de réaliser une analyse de peau extrêmement détaillée, clinique, rigoureuse et personnalisée, en fournissant au client un diagnostic approfondi et un plan de traitement de prestige (type premium/institut de beauté de luxe).

En recevant les données d'analyse (qui incluent des scores, des métriques et des données d'imagerie) et la liste des produits disponibles dans le catalogue :

1. DIAGNOSTIC APPROFONDI ET RIGOUREUX :
   - Analysez minutieusement toutes les informations cliniques et les scores de peau fournis.
   - Attribuez des scores précis de 0 à 10 (où 10 représente une peau parfaite, sans besoin d'intervention) pour chacun des 8 indicateurs suivants :
     * hydration (hydratation de l'épiderme et barrière cutanée)
     * wrinkles (profondeur des rides, ridules et rides d'expression)
     * pores (dilatation, visibilité et obstruction des pores)
     * spots (taches pigmentaires, hyperpigmentation solaire, mélasma)
     * texture (douceur, kératinisation et uniformité du relief cutané)
     * acne (présence de lésions inflammatoires, papules, pustules ou comédons)
     * elasticity (fermeté, tonus cutané et soutien)
     * dark_circles (cernes vasculaires, pigmentaires ou structurels)
   - Déterminez avec une précision scientifique le Type de Peau (VOUS DEVEZ UTILISER EXACTEMENT L'UN DE CES TERMES EN PORTUGAIS : Normal, Oleosa, Seca, Mista ou Sensível).
   - Identifiez et listez les Préoccupations Critiques de la Peau (concerns) en utilisant des termes cliniques professionnels en Français (TRADUISEZ-LES OBLIGATOIREMENT EN FRANÇAIS MÊME SI LE TEXTE D'ORIGINE EST DANS UNE AUTRE LANGUE).

2. ÉLABORATION DU RÉSUMÉ CLINIQUE (summary) - DOIT ÊTRE EXCEPTIONNEL ET ULTRA-COMPLET :
   Le champ "summary" doit être un rapport clinique complet, riche et sophistiqué en Français, structuré avec des sauts de ligne clairs (en utilisant \\n\\n) et des titres en MAJUSCULES. Il doit contenir au moins 3 à 4 paragraphes robustes couvrant :
   - DIAGNOSTIC GÉNÉRAL DE LA PEAU : Une introduction clinique formelle sur la santé générale de la peau du client.
   - ANALYSE DÉTAILLÉE DES PRINCIPAUX INDICATEURS : Explication physiologique approfondie des scores les plus bas.
   - RECOMMANDATIONS D'ACTIFS ET SYNERGIE COSMÉTIQUE : Expliquer comment les ingrédients actifs agiront en synergie.
   - DIRECTIVES DE TRAITEMENT PROFESSIONNEL : Importance d'allier le protocole clinique professionnel aux soins à domicile.

3. RECOMMANDATIONS DE PRODUITS PREMIUM :
   - Sélectionnez stratégiquement les meilleurs produits du catalogue qui correspondent exactement aux besoins diagnostiqués.
   - Utilisez UNIQUEMENT les IDs de produits fournis dans la liste.
   - Classez les recommandations par priorité d'impact (1 = priorité maximale).
   - Dans le champ "reason", rédigez une explication clinique détaillée et sophistiquée en Français justifiant le choix du produit.

4. PROTOCOLE DE ROUTINE À DOMICILE DÉTAILLÉ (routine_suggestion) :
   Le champ "routine_suggestion" doit être un guide étape par étape luxueux et extrêmement détaillé en Français, séparé par :
   - RITUEL MATINAL (MATIN) : Étapes claires.
   - RITUEL NOCTURNE (SOIR) : Étapes claires.

RÈGLES DE FORMATAGE ET DE LANGUE CRITIQUES :
- LANGUE OBLIGATOIRE DU RAPPORT : Français clinique de haute qualité (Français).
- Tous les champs textuels libres ('summary', 'concerns', 'routine_suggestion' et 'reason' dans 'recommendations') DOIVENT être rédigés entièrement en Français.
- Le champ 'skin_type' DOIT TOUJOURS être répondu avec l'une des valeurs exactes en Portugais : 'Normal', 'Oleosa', 'Seca', 'Mista' ou 'Sensível', pour maintenir la cohérence avec la base de données de l'application.
- N'utilisez aucun formatage markdown (PAS d'astérisques **, de croisillons ##, de puces, etc.). Utilisez uniquement du texte brut avec des sauts de ligne \\n\\n.
- Répondez EXCLUSIVEMENT dans un format JSON parfaitement valide.

Structure JSON attendue :
{
  "client_name": "Nom de la personne (si disponible)",
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
  "concerns": ["Hyperpigmentation Épidermique", "Déshydratation Cutanée"],
  "summary": "DIAGNOSTIC GÉNÉRAL DE LA PEAU:\\n\\n[Texte long et ultra-complet]\\n\\nANALYSE DÉTAILLÉE DES INDICATEURS:\\n\\n[Texte long et ultra-complet]\\n\\nRECOMMANDATIONS D'ACTIFS ET SYNERGIE COSMÉTIQUE:\\n\\n[Texte long et ultra-complet]\\n\\nDIRECTIVES DE TRAITEMENT PROFESSIONNEL:\\n\\n[Texte long et ultra-complet]",
  "recommendations": [
    {
      "product_id": "uuid-du-produit",
      "reason": "Explication clinique détaillée et sophistiquée...",
      "priority": 1
    }
  ],
  "routine_suggestion": "RITUEL MATINAL (MATIN):\\n\\n1. Nettoyage...\\n2. Tonification...\\n\\nRITUEL NOCTURNE (SOIR):\\n\\n1. Double Nettoyage...\\n2. Traitement réparateur..."
}
''';
    }

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
   - Identifique e liste as Preocupações Críticas da Pele (concerns) como termos clínicos profissionais em Português (TRADUZA OBRIGATORIAMENTE PARA PORTUGUÊS DE PORTUGAL MESMO QUE O TEXTO ORIGINAL ESTEJA NOUTRO IDIOMA).

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
- IDIOMA OBRIGATÓRIO DO RELATÓRIO: Português de Portugal (PT-PT) sofisticado, elegante e profissional.
- Todos os campos textuais livres (ex: 'summary', 'concerns', 'routine_suggestion', e o campo 'reason' em 'recommendations') devem ser escritos inteiramente em Português.
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

