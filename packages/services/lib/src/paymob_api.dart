import 'dart:convert';

/// Paymob API client wrapper for Firebase Cloud Functions
///
/// This class provides methods to interact with Paymob payment gateway
/// through Firebase Cloud Functions endpoints.
class PaymobApi {
  /// Private constructor to prevent instantiation
  PaymobApi._();

  /// Firebase Cloud Function endpoint names
  static const String _createPaymentFunctionName = 'createPaymobPayment';
  static const String _verifyPaymentFunctionName = 'verifyPaymobHmac';

  /// Creates a payment intent through Paymob
  ///
  /// This method calls the Firebase Cloud Function that handles the Paymob API integration.
  /// It returns a [PaymentIntentResponse] with checkout URL or payment key.
  ///
  /// @param amount The payment amount
  /// @param currency The currency code (default: EGP)
  /// @param orderId The order ID to associate with this payment
  /// @param method The payment method ('card' or 'wallet')
  /// @return A Future that resolves to a PaymentIntentResponse
  static Future<PaymentIntentResponse> createPaymentIntent({
    required double amount,
    String currency = 'EGP',
    required String orderId,
    required String method,
  }) async {
    // This is just the interface - the actual implementation will call
    // Firebase Cloud Functions using the firebase_functions package
    
    // The request payload to send to the Cloud Function
    final Map<String, dynamic> requestData = {
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'method': method,
    };
    
    // In the actual implementation, this would be:
    // final result = await FirebaseFunctions.instance
    //     .httpsCallable(_createPaymentFunctionName)
    //     .call(requestData);
    // return PaymentIntentResponse.fromJson(result.data);
    
    // For now, we just define the interface
    throw UnimplementedError(
      'This method should be called through Firebase Cloud Functions. '
      'Implement in the app using firebase_functions package.'
    );
  }

  /// Verifies a Paymob payment using HMAC
  ///
  /// This method calls the Firebase Cloud Function that verifies the HMAC signature
  /// sent by Paymob in the transaction response.
  ///
  /// @param hmacPayload The HMAC payload received from Paymob
  /// @return A Future that resolves to a boolean indicating if the payment is verified
  static Future<bool> verifyPayment(String hmacPayload) async {
    // This is just the interface - the actual implementation will call
    // Firebase Cloud Functions using the firebase_functions package
    
    // The request payload to send to the Cloud Function
    final Map<String, dynamic> requestData = {
      'hmacPayload': hmacPayload,
    };
    
    // In the actual implementation, this would be:
    // final result = await FirebaseFunctions.instance
    //     .httpsCallable(_verifyPaymentFunctionName)
    //     .call(requestData);
    // return result.data['verified'] as bool;
    
    // For now, we just define the interface
    throw UnimplementedError(
      'This method should be called through Firebase Cloud Functions. '
      'Implement in the app using firebase_functions package.'
    );
  }
}

/// Response model for payment intent creation
class PaymentIntentResponse {
  /// URL for the checkout page (for redirect)
  final String? checkoutUrl;
  
  /// Payment key for the transaction
  final String? paymentKey;
  
  /// Transaction ID from Paymob
  final String? transactionId;
  
  /// Whether the payment intent creation was successful
  final bool success;
  
  /// Error message if the payment intent creation failed
  final String? errorMessage;

  /// Creates a new payment intent response
  PaymentIntentResponse({
    this.checkoutUrl,
    this.paymentKey,
    this.transactionId,
    required this.success,
    this.errorMessage,
  });

  /// Creates a PaymentIntentResponse from JSON data
  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      checkoutUrl: json['checkoutUrl'] as String?,
      paymentKey: json['paymentKey'] as String?,
      transactionId: json['transactionId'] as String?,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Converts this PaymentIntentResponse to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'checkoutUrl': checkoutUrl,
      'paymentKey': paymentKey,
      'transactionId': transactionId,
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'PaymentIntentResponse(success: $success, checkoutUrl: $checkoutUrl, '
           'paymentKey: $paymentKey, transactionId: $transactionId, '
           'errorMessage: $errorMessage)';
  }
}

/// Request model for creating a payment intent
class CreatePaymentRequest {
  /// Amount to charge
  final double amount;
  
  /// Currency code (default: EGP)
  final String currency;
  
  /// Order ID to associate with this payment
  final String orderId;
  
  /// Payment method ('card' or 'wallet')
  final String method;

  /// Creates a new payment request
  CreatePaymentRequest({
    required this.amount,
    this.currency = 'EGP',
    required this.orderId,
    required this.method,
  });

  /// Converts this CreatePaymentRequest to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'method': method,
    };
  }
}

/// Response model for payment verification
class VerifyPaymentResponse {
  /// Whether the payment is verified
  final bool verified;
  
  /// Transaction ID if verified
  final String? transactionId;
  
  /// Order ID associated with this payment
  final String? orderId;
  
  /// Amount that was paid
  final double? amount;
  
  /// Error message if verification failed
  final String? errorMessage;

  /// Creates a new payment verification response
  VerifyPaymentResponse({
    required this.verified,
    this.transactionId,
    this.orderId,
    this.amount,
    this.errorMessage,
  });

  /// Creates a VerifyPaymentResponse from JSON data
  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResponse(
      verified: json['verified'] as bool,
      transactionId: json['transactionId'] as String?,
      orderId: json['orderId'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
