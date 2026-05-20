import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // ============ PRODUCTS ============

  /// Fetch all active products
  Future<List<Product>> getProducts() async {
    final response = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('name');

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all products (including inactive, for admin)
  Future<List<Product>> getAllProducts() async {
    final response = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get single product by ID
  Future<Product?> getProduct(String id) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  /// Get products by list of IDs
  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _client
        .from('products')
        .select()
        .inFilter('id', ids);

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new product
  Future<Product> createProduct(Product product) async {
    final response = await _client
        .from('products')
        .insert(product.toJson())
        .select()
        .single();

    return Product.fromJson(response);
  }

  /// Update a product
  Future<Product> updateProduct(String id, Product product) async {
    final response = await _client
        .from('products')
        .update(product.toJson())
        .eq('id', id)
        .select()
        .single();

    return Product.fromJson(response);
  }

  /// Delete a product (soft delete — mark inactive)
  Future<void> deleteProduct(String id) async {
    await _client.from('products').update({'is_active': false}).eq('id', id);
  }

  /// Hard delete a product
  Future<void> hardDeleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ============ ANALYSES ============

  /// Save an analysis result
  Future<AnalysisResult> saveAnalysis(AnalysisResult analysis) async {
    final response = await _client
        .from('analyses')
        .insert(analysis.toJson())
        .select()
        .single();

    return AnalysisResult.fromJson(response);
  }

  /// Get all past analyses
  Future<List<AnalysisResult>> getAnalyses({int limit = 50}) async {
    final response = await _client
        .from('analyses')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => AnalysisResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single analysis
  Future<AnalysisResult?> getAnalysis(String id) async {
    final response = await _client
        .from('analyses')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AnalysisResult.fromJson(response);
  }

  /// Delete an analysis
  Future<void> deleteAnalysis(String id) async {
    await _client.from('analyses').delete().eq('id', id);
  }

  // ============ ADMIN AUTH ============

  /// Sign in admin with email/password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('admin_users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response != null;
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============ STORAGE ============

  /// Upload product image
  Future<String> uploadProductImage(String fileName, List<int> bytes) async {
    final path = 'products/$fileName';

    await _client.storage
        .from('product-images')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('product-images').getPublicUrl(path);
  }

  /// Upload a client's profile picture to the public storage bucket
  Future<String> uploadClientPhoto(String clientName, List<int> bytes) async {
    final cleanName = clientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final fileName = '${cleanName}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'clients/$fileName';

    await _client.storage
        .from('product-images')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('product-images').getPublicUrl(path);
  }

  /// Sincroniza a imagem de perfil de todas as análises de um determinado cliente
  Future<void> updateClientPhotoUrl(String clientName, String photoUrl) async {
    final response = await _client
        .from('analyses')
        .select()
        .eq('client_name', clientName);

    final list = response as List;

    for (final row in list) {
      final id = row['id'] as String;
      final aiAnalysis = Map<String, dynamic>.from(row['ai_analysis'] as Map? ?? {});
      aiAnalysis['face_image_url'] = photoUrl;

      await _client
          .from('analyses')
          .update({'ai_analysis': aiAnalysis})
          .eq('id', id);
    }
  }

  // ============ STATS (Admin) ============

  /// Get total product count
  Future<int> getProductCount() async {
    final response = await _client
        .from('products')
        .select('id')
        .eq('is_active', true);

    return (response as List).length;
  }

  /// Get total analysis count
  Future<int> getAnalysisCount() async {
    final response = await _client.from('analyses').select('id');
    return (response as List).length;
  }
}
