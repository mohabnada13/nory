import 'package:flutter/foundation.dart';

/// UserProfile model representing user information in the Nory Shop app
class UserProfile {
  /// Unique identifier for the user (Firebase Auth UID)
  final String uid;
  
  /// User's email address
  final String? email;
  
  /// User's display name
  final String? displayName;
  
  /// URL to user's profile photo
  final String? photoUrl;
  
  /// User's phone number
  final String? phoneNumber;
  
  /// Whether this user has admin privileges
  final bool isAdmin;
  
  /// ID of the user's default address (if any)
  final String? defaultAddressId;
  
  /// When the user profile was created
  final DateTime createdAt;
  
  /// When the user profile was last updated
  final DateTime updatedAt;

  /// Creates a new user profile instance
  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.isAdmin = false,
    this.defaultAddressId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfile from JSON data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      defaultAddressId: json['defaultAddressId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this UserProfile to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isAdmin': isAdmin,
      'defaultAddressId': defaultAddressId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this UserProfile with the given fields replaced with new values
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isAdmin,
    String? defaultAddressId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isAdmin: isAdmin ?? this.isAdmin,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserProfile &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.phoneNumber == phoneNumber &&
      other.isAdmin == isAdmin &&
      other.defaultAddressId == defaultAddressId &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      photoUrl,
      phoneNumber,
      isAdmin,
      defaultAddressId,
      createdAt,
      updatedAt,
    );
  }
}
