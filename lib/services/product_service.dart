import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/product_model.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<ProductModel>> getAllProducts() async {
    try {
      debugPrint('🛍️ Fetching all products...');
      
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      debugPrint('📦 Products response: $response');

      if (response == null) {
        debugPrint('⚠️ No products found');
        return [];
      }

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      debugPrint('✅ Loaded ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching products: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<ProductModel>> getExclusiveProducts() async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('is_active', true)
          .eq('is_exclusive', true)
          .limit(5);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch exclusive products: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching product $productId: $e');
      return null;
    }
  }

  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      await _supabase.client
          .from('products')
          .update({'stock': newStock, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating product stock: $e');
      return false;
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _supabase.client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating product: $e');
      rethrow;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _supabase.client
          .from('products')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      return false;
    }
  }
}
