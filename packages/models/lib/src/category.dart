import 'package:flutter/foundation.dart';

/// Category model representing product categories in the Nory Shop app
class Category {
  /// Unique identifier for the category
  final String id;
  
  /// Name of the category
  final String name;
  
  /// URL to the category image
  final String imageUrl;
  
  /// Order in which this category should be displayed (lower values first)
  final int sortOrder;
  
  /// When the category was created
  final DateTime createdAt;
  
  /// When the category was last updated
  final DateTime updatedAt;

  /// Creates a new category instance
  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Category from JSON data
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this Category to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Category with the given fields replaced with new values
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Category &&
      other.id == id &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      other.sortOrder == sortOrder &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      imageUrl,
      sortOrder,
      createdAt,
      updatedAt,
    );
  }
}
