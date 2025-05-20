import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';

/// Service to manage PlaceDetails in Firestore using the new schema:
/// Collection: 'place_details'
class FirebasePlaceDetailsService {
  final CollectionReference _detailsRef =
      FirebaseFirestore.instance.collection('place_details');

  /// Adds or updates a PlaceInformation document in 'place_details'
  Future<void> addPlaceDetails(PlaceInformation place) async {
    await _detailsRef.doc(place.placeId).set(
      place.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Deletes a place detail by its placeId
  Future<void> removePlaceDetails(String placeId) async {
    await _detailsRef.doc(placeId).delete();
  }

  /// Checks if a place detail exists
  Future<bool> placeDetailsExists(String placeId) async {
    final doc = await _detailsRef.doc(placeId).get();
    return doc.exists;
  }

  /// Retrieves all place details
  Future<List<PlaceInformation>> getAllPlaceDetails() async {
    final snapshot = await _detailsRef.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PlaceInformation.fromFirestore(data, doc.id);
    }).toList();
  }

  /// Retrieves a single PlaceInformation by ID, or null if missing
  Future<PlaceInformation?> getPlaceDetailsById(String placeId) async {
    final doc = await _detailsRef.doc(placeId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return PlaceInformation.fromFirestore(data, doc.id);
  }
}
