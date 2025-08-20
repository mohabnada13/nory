import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';
import 'package:services/services.dart';

/// Repository for accessing product and category data from Firestore
class ProductRepository {
  /// Firestore database instance
  final FirebaseFirestore _db;

  /// Creates a new product repository
  ProductRepository(this._db);

  /// Watches the categories collection for real-time updates
  /// 
  /// Returns a stream of categories sorted by sortOrder
  Stream<List<Category>> watchCategories() {
    return _db
        .collection(FirestorePaths.CATEGORIES)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromJson(_mapDates(doc.data(), doc.id)))
            .toList());
  }

  /// Watches the products collection for real-time updates
  /// 
  /// @param categoryId Optional category ID to filter products
  /// @param featuredOnly Whether to only return featured products
  /// @param search Optional search term to filter products by name
  /// @return Stream of products matching the criteria
  Stream<List<Product>> watchProducts({
    String? categoryId,
    bool featuredOnly = false,
    String? search,
  }) {
    Query query = _db.collection(FirestorePaths.PRODUCTS);

    // Apply category filter if provided
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // Apply featured filter if requested
    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    // Apply search filter if provided
    if (search != null && search.isNotEmpty) {
      // This is a simple implementation - in production you would use
      // a more sophisticated search approach like Algolia or Firebase Extensions
      query = query.where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThanOrEqualTo: '$search\uf8ff');
    }

    // Sort by trending score descending, then by name
    query = query.orderBy('trendingScore', descending: true).orderBy('name');

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromJson(_mapDates(doc.data() as Map<String, dynamic>, doc.id)))
        .toList());
  }

  /// Gets a single product by ID
  /// 
  /// @param id The product ID
  /// @return Future resolving to the product or null if not found
  Future<Product?> getProduct(String id) async {
    final doc = await _db.collection(FirestorePaths.PRODUCTS).doc(id).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return Product.fromJson(_mapDates(doc.data()!, doc.id));
  }

  /// Maps Firestore data to the format expected by model classes
  /// 
  /// Handles Timestamp conversion to ISO strings for date fields
  /// @param data The Firestore document data
  /// @param id The document ID to use if not present in data
  /// @return Map with normalized date fields
  Map<String, dynamic> _mapDates(Map<String, dynamic> data, String id) {
    final result = Map<String, dynamic>.from(data);
    
    // Ensure ID is present
    result['id'] = data['id'] ?? id;
    
    // Convert Timestamp to ISO string for createdAt
    if (result['createdAt'] is Timestamp) {
      result['createdAt'] = (result['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    
    // Convert Timestamp to ISO string for updatedAt
    if (result['updatedAt'] is Timestamp) {
      result['updatedAt'] = (result['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    
    return result;
  }
}
