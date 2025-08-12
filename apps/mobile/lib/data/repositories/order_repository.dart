import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:models/models.dart';
import 'package:services/services.dart';

/// Repository for managing orders in Firestore
class OrderRepository {
  /// Firestore database instance
  final FirebaseFirestore _db;
  
  /// Firebase Auth instance for user identification
  final FirebaseAuth _auth;
  
  /// Firebase Functions instance for payment processing
  final FirebaseFunctions _functions;

  /// Creates a new order repository
  OrderRepository(this._db, this._auth, this._functions);

  /// Creates a new order in Firestore
  /// 
  /// @param items The order items
  /// @param address The delivery address
  /// @param deliveryFee The delivery fee (default: 50.0 EGP)
  /// @param discount The discount amount (default: 0.0)
  /// @param promoCode The promo code applied (if any)
  /// @param method The payment method
  /// @return Future resolving to the created Order
  /// @throws StateError if user is not logged in
  Future<Order> createOrder({
    required List<OrderItem> items,
    required Address address,
    double deliveryFee = 50.0,
    double discount = 0.0,
    String? promoCode,
    required PaymentMethod method,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to create an order');
    }
    
    // Calculate subtotal
    double subtotal = 0;
    for (final item in items) {
      subtotal += item.lineTotal;
    }
    
    // Calculate total
    final total = subtotal + deliveryFee - discount;
    
    // Create order document
    final orderRef = _db.collection(FirestorePaths.ORDERS).doc();
    final now = FieldValue.serverTimestamp();
    
    final orderData = {
      'id': orderRef.id,
      'userId': user.uid,
      'items': items.map((item) => item.toJson()).toList(),
      'address': address.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': OrderStatus.processing.name,
      'paymentStatus': PaymentStatus.pending.name,
      'paymentMethod': method.name,
      'promoCode': promoCode,
      'createdAt': now,
      'updatedAt': now,
    };
    
    await orderRef.set(orderData);
    
    // Fetch the created document to get the server timestamps
    final createdDoc = await orderRef.get();
    return Order.fromJson(_mapDates(createdDoc.data()!, orderRef.id));
  }

  /// Creates a payment intent through Paymob
  /// 
  /// @param orderId The order ID
  /// @param amount The payment amount
  /// @param method The payment method ('card' or 'wallet')
  /// @return Future resolving to the payment intent data
  Future<Map<String, dynamic>> createPaymobPayment({
    required String orderId,
    required double amount,
    required String method,
  }) async {
    final callable = _functions.httpsCallable('createPaymobPayment');
    final result = await callable.call({
      'orderId': orderId,
      'amount': amount,
      'method': method,
      'currency': 'EGP',
    });
    
    return result.data as Map<String, dynamic>;
  }

  /// Marks an order's payment as pending
  /// 
  /// @param orderId The order ID
  /// @param transactionId The payment transaction ID (optional)
  /// @return Future that completes when the operation is done
  Future<void> markPaymentPending(String orderId, [String? transactionId]) {
    final updateData = {
      'paymentStatus': PaymentStatus.pending.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }
    
    return _db.collection(FirestorePaths.ORDERS).doc(orderId).update(updateData);
  }

  /// Watches the current user's orders for real-time updates
  /// 
  /// @return Stream of orders sorted by creation date (newest first)
  /// @throws StateError if user is not logged in
  Stream<List<Order>> watchMyOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to watch orders');
    }
    
    return _db
        .collection(FirestorePaths.ORDERS)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(_mapDates(doc.data(), doc.id)))
            .toList());
  }

  /// Gets a single order by ID
  /// 
  /// @param id The order ID
  /// @return Future resolving to the order or null if not found
  Future<Order?> getOrder(String id) async {
    final doc = await _db.collection(FirestorePaths.ORDERS).doc(id).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return Order.fromJson(_mapDates(doc.data()!, doc.id));
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
