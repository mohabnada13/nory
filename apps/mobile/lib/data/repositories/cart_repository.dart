import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:services/services.dart';

/// Data transfer object for cart items stored in Firestore
class CartItemDto {
  /// Product identifier
  final String productId;
  
  /// Product name
  final String name;
  
  /// URL to the product image
  final String imageUrl;
  
  /// Price per unit in Egyptian Pounds
  final double unitPrice;
  
  /// Quantity of the product in cart
  final int quantity;

  /// Creates a new cart item DTO
  CartItemDto({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  /// Creates a CartItemDto from JSON data
  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    return CartItemDto(
      productId: json['productId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  /// Creates a CartItemDto from a Product
  factory CartItemDto.fromProduct(Product product, {int quantity = 1}) {
    return CartItemDto(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      unitPrice: product.priceEgp,
      quantity: quantity,
    );
  }

  /// Converts this CartItemDto to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  /// Converts this CartItemDto to an OrderItem
  OrderItem toOrderItem() {
    return OrderItem(
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}

/// Repository for managing the user's shopping cart in Firestore
class CartRepository {
  /// Firestore database instance
  final FirebaseFirestore _db;
  
  /// Firebase Auth instance for user identification
  final FirebaseAuth _auth;

  /// Creates a new cart repository
  CartRepository(this._db, this._auth);

  /// Watches the user's cart for real-time updates
  /// 
  /// @return Stream of OrderItems in the cart
  /// @throws StateError if user is not logged in
  Stream<List<OrderItem>> watchCart() {
    return _userCartCollection().snapshots().map((snapshot) => 
      snapshot.docs
        .map((doc) => CartItemDto.fromJson(doc.data()).toOrderItem())
        .toList()
    );
  }

  /// Adds a product to the cart
  /// 
  /// If the product is already in the cart, its quantity will be increased
  /// 
  /// @param product The product to add
  /// @param quantity The quantity to add (default: 1)
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final cartRef = _userCartCollection();
    final productDoc = cartRef.doc(product.id);
    
    // Check if product already exists in cart
    final docSnapshot = await productDoc.get();
    
    if (docSnapshot.exists) {
      // Update quantity if product already in cart
      final existingItem = CartItemDto.fromJson(docSnapshot.data()!);
      final newQuantity = existingItem.quantity + quantity;
      
      return productDoc.update({'quantity': newQuantity});
    } else {
      // Add new product to cart
      final cartItem = CartItemDto.fromProduct(product, quantity: quantity);
      return productDoc.set(cartItem.toJson());
    }
  }

  /// Updates the quantity of a product in the cart
  /// 
  /// @param productId The product ID to update
  /// @param quantity The new quantity (must be > 0)
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  /// @throws ArgumentError if quantity is less than 1
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) {
      throw ArgumentError('Quantity must be at least 1');
    }
    
    return _userCartCollection().doc(productId).update({
      'quantity': quantity,
    });
  }

  /// Removes a product from the cart
  /// 
  /// @param productId The product ID to remove
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  Future<void> removeFromCart(String productId) {
    return _userCartCollection().doc(productId).delete();
  }

  /// Clears all items from the cart
  /// 
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  Future<void> clearCart() async {
    final cartRef = _userCartCollection();
    final cartSnapshot = await cartRef.get();
    
    // Create a batch to delete all documents
    final batch = _db.batch();
    for (final doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    return batch.commit();
  }

  /// Calculates the subtotal of all items in the cart
  /// 
  /// @return Future resolving to the cart subtotal
  /// @throws StateError if user is not logged in
  Future<double> subtotal() async {
    final cartSnapshot = await _userCartCollection().get();
    
    double total = 0;
    for (final doc in cartSnapshot.docs) {
      final item = CartItemDto.fromJson(doc.data());
      total += item.unitPrice * item.quantity;
    }
    
    return total;
  }

  /// Gets a reference to the user's cart collection
  /// 
  /// @return CollectionReference to the user's cart
  /// @throws StateError if user is not logged in
  CollectionReference<Map<String, dynamic>> _userCartCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to access cart');
    }
    
    return _db.collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.CART);
  }
}
