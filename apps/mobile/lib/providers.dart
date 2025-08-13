import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

import 'data/repositories/address_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/promo_repository.dart';

/// Firebase service providers
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((_) => FirebaseFunctions.instance);

/// Repository providers
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ProductRepository(firestore);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return CartRepository(firestore, auth);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return OrderRepository(firestore, auth, functions);
});

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return PromoRepository(firestore);
});

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return AddressRepository(firestore, auth);
});

/// Stream providers

/// Provides a stream of all categories
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchCategories();
});

/// Provides a stream of featured products
final featuredProductsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts(featuredOnly: true);
});

/// Provides a stream of products filtered by category
final productsByCategoryProvider = StreamProvider.family<List<Product>, String>((ref, categoryId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts(categoryId: categoryId);
});

/// Provides a stream of the user's cart items
final cartProvider = StreamProvider<List<OrderItem>>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  try {
    return repository.watchCart();
  } catch (e) {
    // Return empty list if user is not logged in
    return Stream.value([]);
  }
});

/// Provides a stream of the user's orders
final myOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  try {
    return repository.watchMyOrders();
  } catch (e) {
    // Return empty list if user is not logged in
    return Stream.value([]);
  }
});

/// Provides the cart subtotal
final cartSubtotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(cartRepositoryProvider);
  try {
    return await repository.subtotal();
  } catch (e) {
    return 0.0;
  }
});

/// Provides a search query state
final searchQueryProvider = StateProvider<String?>((ref) => null);

/// Provides search results based on the current query
final searchResultsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  
  if (query == null || query.isEmpty) {
    return Stream.value([]);
  }
  
  return repository.watchProducts(search: query);
});
