import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { pt, fr }

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.fr; // Default to French as requested

  void toggle() {
    state = state == AppLanguage.fr ? AppLanguage.pt : AppLanguage.fr;
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);


class AppL10n {
  final AppLanguage language;
  AppL10n(this.language);

  static AppL10n of(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return AppL10n(lang);
  }

  String t(String pt, String fr) {
    return language == AppLanguage.fr ? fr : pt;
  }

  // --- HOME SCREEN ---
  String get appName => t('MEBeauty IA', 'MEBeauty IA');
  String get appSubtitle => t('Análise Facial Inteligente', 'Analyse Faciale Intelligente');
  String get howItWorks => t('Como funciona?', 'Comment ça marche ?');
  String get step1 => t('Abre o rapport no app M7', 'Ouvrez le rapport dans l\'application M7');
  String get step2 => t('Clica em "Compartilhar com"', 'Cliquez sur "Partager avec"');
  String get step3 => t('Seleciona MEBeauty IA', 'Sélectionnez MEBeauty IA');
  String get step4 => t('A IA analisa e recomenda produtos', 'L\'IA analyse et recommande les produits');
  String get quickActions => t('Ações Rápidas', 'Actions Rapides');
  String get history => t('Histórico', 'Historique');
  String get historySub => t('Análises anteriores', 'Analyses précédentes');
  String get products => t('Produtos', 'Produits');
  String get productsSub => t('Ver catálogo', 'Voir le catalogue');
  String get recentAnalyses => t('Análises Recentes', 'Analyses Récentes');
  String get sendPdfRapport => t('Enviar Rapport PDF', 'Envoyer Rapport PDF');
  String get emptyStateTitle => t('Nenhuma análise ainda', 'Aucune analyse pour le moment');
  String get emptyStateSub => t('Partilha um rapport do M7 para começar', 'Partagez un rapport M7 pour commencer');
  String get analysisCardRecommended => t('produtos recomendados', 'produits recommandés');

  // --- ANALYSIS / RESULTS SCREEN ---
  String get analysisTitle => t('Análise', 'Analyse');
  String get preparingAnalysis => t('A preparar análise...', 'Préparation de l\'analyse...');
  String get analysisErrorTitle => t('Erro na Análise', 'Erreur d\'Analyse');
  String get back => t('Voltar', 'Retour');
  String get skinTypeLabel => t('Pele', 'Peau');
  String get analysisSummary => t('Resumo da Análise', 'Résumé de l\'Analyse');
  String get skinScores => t('Scores da Pele', 'Scores de la Peau');
  String get identifiedConcerns => t('Preocupações Identificadas', 'Problèmes Identifiés');
  String get suggestedRoutine => t('Rotina Sugerida', 'Routine Suggérée');
  String get recommendedProducts => t('Produtos Recomendados', 'Produits Recommandés');
  String get routineHome => t('Rotina (Casa)', 'Routine (Maison)');
  String get treatmentClinic => t('Tratamento (Clínica)', 'Traitement (Clinique)');
  String get noClinicRecommended => t('Nenhum tratamento clínico recomendado.', 'Aucun traitement clinique recommandé.');
  String get noHomeRecommended => t('Nenhum produto de rotina recomendado.', 'Aucun produit de routine recommandé.');
  String get resultTitle => t('Resultado', 'Résultat');
  String get loadingAnalysis => t('A carregar análise...', 'Chargement de l\'analyse...');
  String get basedOnSkinAnalysis => t('Baseado na análise da tua pele', 'Basé sur l\'analyse de votre peau');

  // --- CLINICAL METRIC LABELS ---
  String translateMetric(String key) {
    final pt = key;
    switch (key.toLowerCase()) {
      case 'hydration': return t('Hidratação', 'Hydratation');
      case 'wrinkles': return t('Rugas', 'Rides');
      case 'pores': return t('Poros', 'Pores');
      case 'spots': return t('Manchas', 'Taches');
      case 'texture': return t('Textura', 'Texture');
      case 'acne': return t('Acne', 'Acné');
      case 'elasticity': return t('Elasticidade', 'Élasticité');
      case 'dark_circles': return t('Olheiras', 'Cernes');
      default: return pt;
    }
  }

  // --- CATALOG SCREEN ---
  String get productCatalogTitle => t('Catálogo de Produtos', 'Catalogue des Produits');
  String get noProductsAvailable => t('Nenhum produto disponível', 'Aucun produit disponible');
  String get addProductsAdminTip => t('Adicione produtos na secção Admin', 'Ajoutez des produits dans la section Admin');

  // --- PRODUCT DETAIL SCREEN ---
  String get price => t('Preço:', 'Prix :');
  String get brand => t('Marca:', 'Marque :');
  String get category => t('Categoria:', 'Catégorie :');
  String get attributes => t('Atributos:', 'Attributs :');
  String get ingredients => t('Ingredientes:', 'Ingrédients :');
  String get usageMethod => t('Modo de uso:', 'Mode d\'utilisation :');
  String get skinTypes => t('Tipos de pele:', 'Types de peau :');
  String get gender => t('Género:', 'Genre :');
  String get crowd => t('Público-alvo:', 'Public cible :');
  String get clinicOnly => t('Apenas Clínica', 'Usage Clinique Uniquement');
  String get clinicOnlySub => t('Apenas para uso na clínica pelo profissional', 'Uniquement pour usage en clinique par le professionnel');
  String get visitWebsite => t('Visitar Website', 'Visiter le site Web');
  String get clinicalUse => t('Tratamento Clínico', 'Soin Clinique');
  String get homecareUse => t('Rotina Casa', 'Soins à Domicile');

  // --- HISTORY SCREEN ---
  String get historyTitle => t('Histórico de Análises', 'Historique des Analyses');
  String get delete => t('Eliminar', 'Supprimer');
  String get deleteConfirm => t('Tem a certeza que deseja eliminar esta análise?', 'Êtes-vous sûr de vouloir supprimer cette analyse ?');
  String get cancel => t('Cancelar', 'Annuler');

  // --- ADMIN SCREENS ---
  String get adminTitle => t('Área Administrativa', 'Zone Administrative');
  String get adminLoginTitle => t('Acesso Administrativo', 'Accès Administratif');
  String get email => t('E-mail', 'E-mail');
  String get password => t('Palavra-passe', 'Mot de passe');
  String get login => t('Entrar', 'Se connecter');
  String get loggingIn => t('A entrar...', 'Connexion...');
  String get loginError => t('Erro ao fazer login', 'Erreur lors de la connexion');
  String get adminDashboard => t('Painel de Controlo', 'Tableau de Bord');
  String get totalProducts => t('Total de Produtos', 'Total des Produits');
  String get totalAnalyses => t('Total de Análises', 'Total des Analyses');
  String get manageProducts => t('Gerir Produtos', 'Gérer les Produits');
  String get logout => t('Sair', 'Se déconnecter');
  String get selectLanguage => t('Selecionar Idioma', 'Choisir la langue');

  // --- ADMIN PRODUCTS LIST ---
  String get edit => t('Editar', 'Modifier');
  String get active => t('Ativo', 'Actif');
  String get inactive => t('Inativo', 'Inactif');
  String get newProduct => t('Novo Produto', 'Nouveau Produit');

  // --- ADMIN PRODUCT FORM ---
  String get editProduct => t('Editar Produto', 'Modifier le Produit');
  String get saveChanges => t('Guardar Alterações', 'Enregistrer les Modifications');
  String get createProduct => t('Criar Produto', 'Créer le Produit');
  String get saving => t('A guardar...', 'Enregistrement...');
  String get imageSection => t('Foto do Produto', 'Photo du Produit');
  String get imageTapTip => t('Toca para adicionar foto', 'Appuyez pour ajouter une photo');
  String get imageSpecsTip => t('JPG ou PNG • Tamanho recomendado: 551×421', 'JPG ou PNG • Taille recommandée : 551×421');
  String get imageChange => t('Alterar', 'Modifier');
  String get basicInfo => t('Informações Básicas', 'Informations de Base');
  String get fieldName => t('Nome do Produto *', 'Nom du Produit *');
  String get fieldBrand => t('Marca', 'Marque');
  String get fieldPrice => t('Preço (€) *', 'Prix (€) *');
  String get fieldSpecialPrice => t('Preço Especial (€)', 'Prix Spécial (€)');
  String get fieldWebsite => t('Website', 'Site Web');
  String get fieldCategory => t('Categoria *', 'Catégorie *');
  String get fieldGender => t('Género Aplicável *', 'Genre Applicable *');
  String get fieldSkinCondition => t('Condição de Pele Aplicável *', 'État de Peau Applicable *');
  String get fieldIndicators => t('Indicadores Correlacionados *', 'Indicateurs Corrélés *');
  String get indicatorsTip => t('Seleciona os parâmetros medidos pelo dispositivo', 'Sélectionnez les paramètres mesurés par l\'appareil');
  String get fieldCrowd => t('Público-Alvo *', 'Public Cible *');
  String get fieldDetails => t('Detalhes do Produto', 'Détails du Produit');
  String get fieldAttribute => t('Atributo do Produto', 'Attribut du Produit');
  String get fieldUsageMethod => t('Modo de Utilização (máx. 40 caracteres)', 'Mode d\'Emploi (max. 40 caractères)');
  String get fieldDescription => t('Descrição', 'Description');
  String get fieldIngredients => t('Ingredientes', 'Ingrédients');
  String get fieldSkinTypes => t('Tipos de Pele (para IA)', 'Types de Peau (pour l\'IA)');
  String get fieldAvailability => t('Estado & Disponibilidade', 'Statut & Disponibilité');
  String get fieldIsInternal => t('Produto Interno (Apenas Clínica)', 'Produit Interne (Clinique Uniquement)');
  String get fieldIsInternalSub => t('Recomendado como tratamento em clínica', 'Recommandé comme traitement en clinique');
  String get fieldIsActive => t('Produto ativo', 'Produit actif');
  String get fieldIsActiveSub => t('Produtos inativos não aparecem no catálogo', 'Les produits inactifs n\'apparaissent pas dans le catalogue');
  String get requiredField => t('Obrigatório', 'Obligatoire');
  String get errorSaving => t('Erro ao salvar', 'Erreur lors de l\'enregistrement');
  String get productSaved => t('Produto salvo com sucesso!', 'Produit enregistré avec succès !');

  // --- AI FILL FEATURE ---
  String get fillWithAi => t('Preencher com IA', 'Remplir par IA');
  String get aiFillNoImage => t('Por favor, selecione ou tire uma foto do produto primeiro!', 'Veuillez d\'abord sélectionner ou prendre une photo du produit !');
  String get aiFillAnalyzing => t('A analisar imagem...', 'Analyse de l\'image...');
  String get aiFillSuccess => t('Campos preenchidos com IA com sucesso!', 'Champs remplis par l\'IA avec succès !');
  String get aiFillError => t('Erro no preenchimento de IA: ', 'Erreur de remplissage de l\'IA : ');

  // --- DYNAMIC DATA TRANSLATIONS ---
  String translateCategory(String cat) {
    switch (cat) {
      case 'Limpeza': return t('Limpeza', 'Nettoyage');
      case 'Tónico': return t('Tónico', 'Tonique');
      case 'Sérum': return t('Sérum', 'Sérum');
      case 'Hidratante': return t('Hidratante', 'Hydratant');
      case 'Protetor Solar': return t('Protetor Solar', 'Écran Solaire');
      case 'Esfoliante': return t('Esfoliante', 'Exfoliant');
      case 'Máscara': return t('Máscara', 'Masque');
      case 'Contorno de Olhos': return t('Contorno de Olhos', 'Contour des Yeux');
      case 'Tratamento': return t('Tratamento', 'Traitement');
      case 'Suplemento': return t('Suplemento', 'Supplément');
      default: return cat;
    }
  }

  String translateGender(String? g) {
    if (g == null) return '';
    if (g.contains('Masculino')) return t('01-Masculino', '01-Masculin');
    if (g.contains('Feminino')) return t('02-Feminino', '02-Féminin');
    if (g.contains('Unissexo')) return t('03-Unissexo', '03-Unisexe');
    return g;
  }

  String translateSkinCondition(String? s) {
    if (s == null) return '';
    switch (s) {
      case 'Boa': return t('Boa', 'Bonne');
      case 'Média': return t('Média', 'Moyenne');
      case 'Geral': return t('Geral', 'Générale');
      case 'Fraca': return t('Fraca', 'Faible');
      case 'Grave': return t('Grave', 'Grave');
      default: return s;
    }
  }

  String translateSkinType(String tType) {
    switch (tType) {
      case 'Normal': return t('Normal', 'Normale');
      case 'Oleosa': return t('Oleosa', 'Grasse');
      case 'Seca': return t('Seca', 'Sèche');
      case 'Mista': return t('Mista', 'Mixte');
      case 'Sensível': return t('Sensível', 'Sensible');
      default: return tType;
    }
  }

  String translateCrowd(String c) {
    if (c.contains('Jovem') && !c.contains('Adulto')) return t('01-Jovem', '01-Jeune');
    if (c.contains('Adulto Jovem')) return t('02-Adulto Jovem', '02-Jeune Adulte');
    if (c.contains('Meia-Idade')) return t('03-Meia-Idade', '03-Moyen Âge');
    if (c.contains('Sénior')) return t('04-Sénior', '04-Sénior');
    if (c.contains('Todos')) return t('05-Todos', '05-Tous');
    return c;
  }

  String translateIndicator(String ind) {
    switch (ind) {
      case 'Poros': return t('Poros', 'Pores');
      case 'Porfirina': return t('Porfirina', 'Porphyrine');
      case 'Acne': return t('Acne', 'Acné');
      case 'Sebo': return t('Sebo', 'Sébum');
      case 'Poro Entupido': return t('Poro Entupido', 'Pores Obstrués');
      case 'Pigmento Epidérmico': return t('Pigmento Epidérmico', 'Pigment Épidermique');
      case 'Pigmento Dérmico': return t('Pigmento Dérmico', 'Pigment Dermique');
      case 'Área Castanha': return t('Área Castanha', 'Zone Brune');
      case 'Dano UV': return t('Dano UV', 'Dommages UV');
      case 'Melasma': return t('Melasma', 'Mélasme');
      case 'Área Sensível': return t('Área Sensível', 'Zone Sensible');
      case 'Vasos Capilares': return t('Vasos Capilares', 'Vaisseaux Capillaires');
      case 'Térmica': return t('Térmica', 'Thermique');
      case 'Borbulha': return t('Borbulha', 'Bouton');
      case 'Ruga': return t('Ruga', 'Ride');
      case 'Textura': return t('Textura', 'Texture');
      case 'Hidratação': return t('Hidratação', 'Hydratation');
      case 'Colágenio': return t('Colágenio', 'Collagène');
      default: return ind;
    }
  }
}
