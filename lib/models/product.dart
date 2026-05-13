class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double? price;
  final double? specialPrice;
  final String? imageUrl;
  final List<String> skinConcerns;
  final List<String> skinTypes;
  final String? ingredients;
  final String? brand;
  final String? website;
  final String? applicableGender;
  final String? applicationSkin;
  final List<String> indicatorCorrelation;
  final List<String> applicableCrowd;
  final String? productAttribute;
  final String? usageMethod;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.price,
    this.specialPrice,
    this.imageUrl,
    this.skinConcerns = const [],
    this.skinTypes = const [],
    this.ingredients,
    this.brand,
    this.website,
    this.applicableGender,
    this.applicationSkin,
    this.indicatorCorrelation = const [],
    this.applicableCrowd = const [],
    this.productAttribute,
    this.usageMethod,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      specialPrice: json['special_price'] != null
          ? (json['special_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      skinConcerns: json['skin_concerns'] != null
          ? List<String>.from(json['skin_concerns'] as List)
          : [],
      skinTypes: json['skin_types'] != null
          ? List<String>.from(json['skin_types'] as List)
          : [],
      ingredients: json['ingredients'] as String?,
      brand: json['brand'] as String?,
      website: json['website'] as String?,
      applicableGender: json['applicable_gender'] as String?,
      applicationSkin: json['application_skin'] as String?,
      indicatorCorrelation: json['indicator_correlation'] != null
          ? List<String>.from(json['indicator_correlation'] as List)
          : [],
      applicableCrowd: json['applicable_crowd'] != null
          ? List<String>.from(json['applicable_crowd'] as List)
          : [],
      productAttribute: json['product_attribute'] as String?,
      usageMethod: json['usage_method'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'special_price': specialPrice,
      'image_url': imageUrl,
      'skin_concerns': skinConcerns,
      'skin_types': skinTypes,
      'ingredients': ingredients,
      'brand': brand,
      'website': website,
      'applicable_gender': applicableGender,
      'application_skin': applicationSkin,
      'indicator_correlation': indicatorCorrelation,
      'applicable_crowd': applicableCrowd,
      'product_attribute': productAttribute,
      'usage_method': usageMethod,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    double? specialPrice,
    String? imageUrl,
    List<String>? skinConcerns,
    List<String>? skinTypes,
    String? ingredients,
    String? brand,
    String? website,
    String? applicableGender,
    String? applicationSkin,
    List<String>? indicatorCorrelation,
    List<String>? applicableCrowd,
    String? productAttribute,
    String? usageMethod,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      specialPrice: specialPrice ?? this.specialPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      skinTypes: skinTypes ?? this.skinTypes,
      ingredients: ingredients ?? this.ingredients,
      brand: brand ?? this.brand,
      website: website ?? this.website,
      applicableGender: applicableGender ?? this.applicableGender,
      applicationSkin: applicationSkin ?? this.applicationSkin,
      indicatorCorrelation: indicatorCorrelation ?? this.indicatorCorrelation,
      applicableCrowd: applicableCrowd ?? this.applicableCrowd,
      productAttribute: productAttribute ?? this.productAttribute,
      usageMethod: usageMethod ?? this.usageMethod,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Short summary for GPT prompt context
  String toPromptSummary() {
    final indicators = indicatorCorrelation.isNotEmpty
        ? indicatorCorrelation.join(', ')
        : skinConcerns.join(', ');
    return '[$id] $name ($category) - '
        'Género: ${applicableGender ?? "Unisex"}. '
        'Para: ${applicableCrowd.join(", ")}. '
        'Indicadores: $indicators. '
        '${description ?? ""}';
  }
}
