import 'package:flutter/foundation.dart';

/// Promo model representing promotional codes in the Nory Shop app
class Promo {
  /// Unique identifier for the promo
  final String id;
  
  /// Promotional code that users enter
  final String code;
  
  /// Type of discount: 'percent' or 'amount'
  final String type;
  
  /// Value of discount (percentage or fixed amount in EGP)
  final double value;
  
  /// Minimum order value required to apply this promo (in EGP)
  final double minOrder;
  
  /// When this promo expires
  final DateTime expiresAt;
  
  /// Whether this promo is currently active
  final bool active;
  
  /// When the promo was created
  final DateTime createdAt;
  
  /// When the promo was last updated
  final DateTime updatedAt;

  /// Creates a new promo instance
  Promo({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrder = 0,
    required this.expiresAt,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(type == 'percent' || type == 'amount'),
       assert(type == 'percent' ? value <= 100 : true);

  /// Creates a Promo from JSON data
  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      minOrder: (json['minOrder'] as num?)?.toDouble() ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this Promo to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'minOrder': minOrder,
      'expiresAt': expiresAt.toIso8601String(),
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Applies the promo to the given total and returns the discounted amount
  /// Returns the original total if:
  /// - Promo is not active
  /// - Promo has expired
  /// - Order total is less than minimum required
  double apply(double total) {
    // Check if promo is valid and applicable
    if (!active || DateTime.now().isAfter(expiresAt) || total < minOrder) {
      return total;
    }

    // Apply discount based on type
    if (type == 'percent') {
      // Calculate percentage discount
      final discount = total * (value / 100);
      return total - discount;
    } else {
      // Apply fixed amount discount, ensuring total doesn't go below zero
      return (total > value) ? total - value : 0;
    }
  }

  /// Creates a copy of this Promo with the given fields replaced with new values
  Promo copyWith({
    String? id,
    String? code,
    String? type,
    double? value,
    double? minOrder,
    DateTime? expiresAt,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Promo(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrder: minOrder ?? this.minOrder,
      expiresAt: expiresAt ?? this.expiresAt,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if this promo is currently valid (active and not expired)
  bool get isValid => active && DateTime.now().isBefore(expiresAt);

  @override
  String toString() {
    return 'Promo(id: $id, code: $code, type: $type, value: $value, minOrder: $minOrder, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Promo &&
      other.id == id &&
      other.code == code &&
      other.type == type &&
      other.value == value &&
      other.minOrder == minOrder &&
      other.expiresAt == expiresAt &&
      other.active == active &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      code,
      type,
      value,
      minOrder,
      expiresAt,
      active,
      createdAt,
      updatedAt,
    );
  }
}
