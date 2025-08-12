/// Helper class for Firestore paths used throughout the app
///
/// Provides standardized access to collection and document paths to maintain
/// consistency and avoid typos when accessing Firestore data.
class FirestorePaths {
  /// Private constructor to prevent instantiation
  FirestorePaths._();
  
  // Collection names
  /// Products collection path
  static const String PRODUCTS = 'products';
  
  /// Categories collection path
  static const String CATEGORIES = 'categories';
  
  /// Users collection path
  static const String USERS = 'users';
  
  /// Orders collection path
  static const String ORDERS = 'orders';
  
  /// Promos collection path
  static const String PROMOS = 'promos';
  
  /// Addresses subcollection name
  static const String ADDRESSES = 'addresses';
  
  /// Cart subcollection name
  static const String CART = 'cart';

  // Document paths
  
  /// Returns the path to a user document
  /// 
  /// @param uid The user ID
  /// @return The path to the user document
  static String userDoc(String uid) => '$USERS/$uid';
  
  /// Returns the path to a user's addresses collection
  /// 
  /// @param uid The user ID
  /// @return The path to the user's addresses collection
  static String userAddresses(String uid) => '${userDoc(uid)}/$ADDRESSES';
  
  /// Returns the path to a user's cart document
  /// 
  /// @param uid The user ID
  /// @return The path to the user's cart document
  static String userCart(String uid) => '${userDoc(uid)}/$CART';
  
  /// Returns the path to an order document
  /// 
  /// @param id The order ID
  /// @return The path to the order document
  static String orderDoc(String id) => '$ORDERS/$id';
  
  /// Returns the path to a product document
  /// 
  /// @param id The product ID
  /// @return The path to the product document
  static String productDoc(String id) => '$PRODUCTS/$id';
  
  /// Returns the path to a category document
  /// 
  /// @param id The category ID
  /// @return The path to the category document
  static String categoryDoc(String id) => '$CATEGORIES/$id';
  
  /// Returns the path to a promo document
  /// 
  /// @param id The promo ID
  /// @return The path to the promo document
  static String promoDoc(String id) => '$PROMOS/$id';
}
