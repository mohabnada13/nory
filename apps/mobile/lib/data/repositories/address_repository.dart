import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:services/services.dart';

/// Repository for managing user addresses in Firestore
class AddressRepository {
  /// Firestore database instance
  final FirebaseFirestore _db;
  
  /// Firebase Auth instance for user identification
  final FirebaseAuth _auth;

  /// Creates a new address repository
  AddressRepository(this._db, this._auth);

  /// Watches the current user's addresses for real-time updates
  /// 
  /// @return Stream of addresses
  /// @throws StateError if user is not logged in
  Stream<List<Address>> watchMyAddresses() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to access addresses');
    }
    
    return _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Address.fromJson(_mapDates(doc.data(), doc.id)))
            .toList());
  }

  /// Adds a new address for the current user
  /// 
  /// @param address The address to add
  /// @return Future resolving to the created Address
  /// @throws StateError if user is not logged in
  Future<Address> add(Address address) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to add an address');
    }
    
    // Create address document
    final addressRef = _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .doc();
    
    // Prepare data with server timestamps
    final now = FieldValue.serverTimestamp();
    final addressData = address.toJson();
    addressData['id'] = addressRef.id;
    addressData['userId'] = user.uid;
    addressData['createdAt'] = now;
    addressData['updatedAt'] = now;
    
    // If this is the first address or marked as default, handle default status
    if (addressData['isDefault'] == true) {
      await _clearOtherDefaults();
    }
    
    // Save to Firestore
    await addressRef.set(addressData);
    
    // Fetch the created document to get the server timestamps
    final createdDoc = await addressRef.get();
    return Address.fromJson(_mapDates(createdDoc.data()!, addressRef.id));
  }

  /// Updates an existing address
  /// 
  /// @param address The address to update
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  Future<void> update(Address address) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to update an address');
    }
    
    // Prepare update data
    final updateData = address.toJson();
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    
    // If setting as default, clear other defaults first
    if (address.isDefault) {
      await _clearOtherDefaults(exceptId: address.id);
    }
    
    // Update the document
    return _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .doc(address.id)
        .update(updateData);
  }

  /// Removes an address
  /// 
  /// @param id The address ID to remove
  /// @return Future that completes when the operation is done
  /// @throws StateError if user is not logged in
  Future<void> remove(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to remove an address');
    }
    
    return _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .doc(id)
        .delete();
  }

  /// Gets the user's default address
  /// 
  /// @return Future resolving to the default Address or null if none found
  /// @throws StateError if user is not logged in
  Future<Address?> getDefault() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to get default address');
    }
    
    final snapshot = await _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return null;
    }
    
    final doc = snapshot.docs.first;
    return Address.fromJson(_mapDates(doc.data(), doc.id));
  }

  /// Clears the default flag from all addresses except the specified one
  /// 
  /// @param exceptId Optional ID to exclude from the update
  /// @return Future that completes when the operation is done
  Future<void> _clearOtherDefaults({String? exceptId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    
    final batch = _db.batch();
    final snapshot = await _db
        .collection(FirestorePaths.USERS)
        .doc(user.uid)
        .collection(FirestorePaths.ADDRESSES)
        .where('isDefault', isEqualTo: true)
        .get();
    
    for (final doc in snapshot.docs) {
      if (exceptId == null || doc.id != exceptId) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    return batch.commit();
  }

  /// Maps Firestore data to the format expected by model classes
  /// 
  /// Handles Timestamp conversion to ISO strings for date fields
  /// @param data The Firestore document data
  /// @param id The document ID to use if not present in data
  /// @return Map with normalized date fields
  Map<String, dynamic> _mapDates(Map<String, dynamic> data, String id) {
    final result = Map<String, dynamic>.from(data);
    
    // Ensure ID is present
    result['id'] = data['id'] ?? id;
    
    // Convert Timestamp to ISO string for createdAt
    if (result['createdAt'] is Timestamp) {
      result['createdAt'] = (result['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    
    // Convert Timestamp to ISO string for updatedAt
    if (result['updatedAt'] is Timestamp) {
      result['updatedAt'] = (result['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    
    return result;
  }
}
