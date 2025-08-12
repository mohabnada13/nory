import 'package:flutter/foundation.dart';

/// Product model representing bakery and sweet items in the Nory Shop app
class Product {
  /// Unique identifier for the product
  final String id;
  
  /// Name of the product
  final String name;
  
  /// Detailed description of the product
  final String description;
  
  /// List of ingredients used in the product
  final String ingredients;
  
  /// URL to the product image
  final String imageUrl;
  
  /// Price in Egyptian Pounds
  final double priceEgp;
  
  /// Category identifier this product belongs to
  final String categoryId;
  
  /// Whether this product is featured on the home page
  final bool isFeatured;
  
  /// Score to determine trending products (higher = more trending)
  final int trendingScore;
  
  /// When the product was created
  final DateTime createdAt;
  
  /// When the product was last updated
  final DateTime updatedAt;

  /// Creates a new product instance
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.imageUrl,
    required this.priceEgp,
    required this.categoryId,
    this.isFeatured = false,
    this.trendingScore = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Product from JSON data
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ingredients: json['ingredients'] as String,
      imageUrl: json['imageUrl'] as String,
      priceEgp: (json['priceEgp'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      isFeatured: json['isFeatured'] as bool? ?? false,
      trendingScore: json['trendingScore'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this Product to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'priceEgp': priceEgp,
      'categoryId': categoryId,
      'isFeatured': isFeatured,
      'trendingScore': trendingScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Product with the given fields replaced with new values
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? ingredients,
    String? imageUrl,
    double? priceEgp,
    String? categoryId,
    bool? isFeatured,
    int? trendingScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      priceEgp: priceEgp ?? this.priceEgp,
      categoryId: categoryId ?? this.categoryId,
      isFeatured: isFeatured ?? this.isFeatured,
      trendingScore: trendingScore ?? this.trendingScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, priceEgp: $priceEgp, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Product &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.ingredients == ingredients &&
      other.imageUrl == imageUrl &&
      other.priceEgp == priceEgp &&
      other.categoryId == categoryId &&
      other.isFeatured == isFeatured &&
      other.trendingScore == trendingScore &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      ingredients,
      imageUrl,
      priceEgp,
      categoryId,
      isFeatured,
      trendingScore,
      createdAt,
      updatedAt,
    );
  }
}
