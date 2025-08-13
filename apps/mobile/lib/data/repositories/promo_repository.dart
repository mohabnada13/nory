import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';
import 'package:services/services.dart';

/// Repository for accessing promo codes from Firestore
class PromoRepository {
  /// Firestore database instance
  final FirebaseFirestore _db;

  /// Creates a new promo repository
  PromoRepository(this._db);

  /// Gets a promo by its code
  /// 
  /// @param code The promo code to look up
  /// @return Future resolving to the Promo if found, null otherwise
  Future<Promo?> getByCode(String code) async {
    final snapshot = await _db
        .collection(FirestorePaths.PROMOS)
        .where('code', isEqualTo: code)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return null;
    }
    
    final doc = snapshot.docs.first;
    return Promo.fromJson(_mapDates(doc.data(), doc.id));
  }

  /// Calculates the discount amount for a subtotal using a promo
  /// 
  /// @param promo The promo to apply
  /// @param subtotal The subtotal to apply the promo to
  /// @return The discounted amount after applying the promo
  double calculateDiscount(Promo promo, double subtotal) {
    return subtotal - promo.apply(subtotal);
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
    
    // Convert Timestamp to ISO string for expiresAt
    if (result['expiresAt'] is Timestamp) {
      result['expiresAt'] = (result['expiresAt'] as Timestamp).toDate().toIso8601String();
    }
    
    return result;
  }
}
