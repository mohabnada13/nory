/// Configuration for the Nory Shop app
/// 
/// Contains placeholders for API keys and constants used throughout the app.
/// These values will be replaced with actual values from Remote Config or
/// environment variables in a production environment.

/// Configuration for API keys and integration IDs
class AppConfig {
  /// Private constructor to prevent instantiation
  AppConfig._();
  
  /// Paymob API key for authentication
  /// Replace with actual API key in production
  static const String PAYMOB_API_KEY = 'placeholder_api_key';
  
  /// HMAC secret for Paymob transaction verification
  /// Replace with actual HMAC in production
  static const String PAYMOB_HMAC = 'placeholder_hmac';
  
  /// Paymob merchant ID
  /// Replace with actual merchant ID in production
  static const String MERCHANT_ID = 'placeholder_merchant_id';
  
  /// Paymob integration ID for card payments
  /// Replace with actual integration ID in production
  static const String INTEGRATION_ID_CARD = 'placeholder_integration_id_card';
  
  /// Paymob integration ID for mobile wallet payments
  /// Replace with actual integration ID in production
  static const String INTEGRATION_ID_WALLET = 'placeholder_integration_id_wallet';
}

/// Constants used throughout the app
class Constants {
  /// Private constructor to prevent instantiation
  Constants._();
  
  /// Fixed delivery fee in EGP
  static const double DELIVERY_FEE = 50.0;
  
  /// Currency code for Egyptian Pound
  static const String CURRENCY_CODE = 'EGP';
  
  /// Currency symbol for Egyptian Pound
  static const String CURRENCY_SYMBOL = 'EGP';
}
