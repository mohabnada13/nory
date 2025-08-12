/// Address model representing delivery addresses in the Nory Shop app
class Address {
  /// Unique identifier for the address
  final String id;
  
  /// User ID that owns this address
  final String userId;
  
  /// Full name of the recipient
  final String fullName;
  
  /// Phone number for delivery contact
  final String phone;
  
  /// City (defaults to Cairo)
  final String city;
  
  /// Area/neighborhood within the city
  final String area;
  
  /// Street name/number
  final String street;
  
  /// Building name/number
  final String building;
  
  /// Apartment/unit number
  final String apartment;
  
  /// Additional delivery instructions
  final String notes;
  
  /// Whether this is the default delivery address
  final bool isDefault;
  
  /// When the address was created
  final DateTime createdAt;
  
  /// When the address was last updated
  final DateTime updatedAt;

  /// Creates a new address instance
  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.city = 'Cairo',
    required this.area,
    required this.street,
    required this.building,
    required this.apartment,
    this.notes = '',
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an Address from JSON data
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String? ?? 'Cairo',
      area: json['area'] as String,
      street: json['street'] as String,
      building: json['building'] as String,
      apartment: json['apartment'] as String,
      notes: json['notes'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this Address to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'city': city,
      'area': area,
      'street': street,
      'building': building,
      'apartment': apartment,
      'notes': notes,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Address with the given fields replaced with new values
  Address copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? city,
    String? area,
    String? street,
    String? building,
    String? apartment,
    String? notes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      area: area ?? this.area,
      street: street ?? this.street,
      building: building ?? this.building,
      apartment: apartment ?? this.apartment,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, userId: $userId, fullName: $fullName, area: $area, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Address &&
      other.id == id &&
      other.userId == userId &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.city == city &&
      other.area == area &&
      other.street == street &&
      other.building == building &&
      other.apartment == apartment &&
      other.notes == notes &&
      other.isDefault == isDefault &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      fullName,
      phone,
      city,
      area,
      street,
      building,
      apartment,
      notes,
      isDefault,
      createdAt,
      updatedAt,
    );
  }
}
