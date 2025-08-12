import 'package:flutter/foundation.dart';
import 'address.dart';

/// Order status representing the current state of an order
enum OrderStatus {
  processing,
  baking,
  out_for_delivery,
  delivered,
}

/// Payment status representing the current state of payment
enum PaymentStatus {
  pending,
  paid,
  failed,
}

/// Payment method used for the order
enum PaymentMethod {
  paymob_card,
  paymob_wallet,
}

/// Order item representing a product in an order
class OrderItem {
  /// Product identifier
  final String productId;
  
  /// Product name
  final String name;
  
  /// URL to the product image
  final String imageUrl;
  
  /// Price per unit in Egyptian Pounds
  final double unitPrice;
  
  /// Quantity ordered
  final int quantity;
  
  /// Total price for this line item (unitPrice * quantity)
  double get lineTotal => unitPrice * quantity;

  /// Creates a new order item instance
  OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  /// Creates an OrderItem from JSON data
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  /// Converts this OrderItem to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }

  /// Creates a copy of this OrderItem with the given fields replaced with new values
  OrderItem copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'OrderItem(productId: $productId, name: $name, quantity: $quantity, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OrderItem &&
      other.productId == productId &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      other.unitPrice == unitPrice &&
      other.quantity == quantity;
  }

  @override
  int get hashCode {
    return Object.hash(
      productId,
      name,
      imageUrl,
      unitPrice,
      quantity,
    );
  }
}

/// Order model representing customer orders in the Nory Shop app
class Order {
  /// Unique identifier for the order
  final String id;
  
  /// User ID that placed this order
  final String userId;
  
  /// List of ordered items
  final List<OrderItem> items;
  
  /// Delivery address for this order
  final Address address;
  
  /// Subtotal before delivery fee and discounts
  final double subtotal;
  
  /// Delivery fee (flat 50 EGP)
  final double deliveryFee;
  
  /// Discount amount applied
  final double discount;
  
  /// Final total (subtotal + deliveryFee - discount)
  final double total;
  
  /// Current status of the order
  final OrderStatus status;
  
  /// Current payment status
  final PaymentStatus paymentStatus;
  
  /// Payment method used
  final PaymentMethod paymentMethod;
  
  /// Promo code applied to this order (if any)
  final String? promoCode;
  
  /// When the order was created
  final DateTime createdAt;
  
  /// When the order was last updated
  final DateTime updatedAt;

  /// Creates a new order instance
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.address,
    required this.subtotal,
    this.deliveryFee = 50.0, // Default flat fee of 50 EGP
    this.discount = 0.0,
    required this.total,
    this.status = OrderStatus.processing,
    this.paymentStatus = PaymentStatus.pending,
    required this.paymentMethod,
    this.promoCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an Order from JSON data
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.byName(json['status'] as String),
      paymentStatus: PaymentStatus.values.byName(json['paymentStatus'] as String),
      paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
      promoCode: json['promoCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this Order to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'address': address.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'promoCode': promoCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Order with the given fields replaced with new values
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    Address? address,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? promoCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      address: address ?? this.address,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Updates the order status to the next stage in the order lifecycle
  Order progressStatus() {
    switch (status) {
      case OrderStatus.processing:
        return copyWith(
          status: OrderStatus.baking,
          updatedAt: DateTime.now(),
        );
      case OrderStatus.baking:
        return copyWith(
          status: OrderStatus.out_for_delivery,
          updatedAt: DateTime.now(),
        );
      case OrderStatus.out_for_delivery:
        return copyWith(
          status: OrderStatus.delivered,
          updatedAt: DateTime.now(),
        );
      case OrderStatus.delivered:
        return this; // Already at final status
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, items: ${items.length}, total: $total, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Order &&
      other.id == id &&
      other.userId == userId &&
      listEquals(other.items, items) &&
      other.address == address &&
      other.subtotal == subtotal &&
      other.deliveryFee == deliveryFee &&
      other.discount == discount &&
      other.total == total &&
      other.status == status &&
      other.paymentStatus == paymentStatus &&
      other.paymentMethod == paymentMethod &&
      other.promoCode == promoCode &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      Object.hashAll(items),
      address,
      subtotal,
      deliveryFee,
      discount,
      total,
      status,
      paymentStatus,
      paymentMethod,
      promoCode,
      createdAt,
      updatedAt,
    );
  }
}
