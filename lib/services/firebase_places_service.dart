import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirebasePlacesService {
  final CollectionReference _placesRef = FirebaseFirestore.instance.collection('places');

  /// Guarda un lugar en Firebase
  Future<void> addPlace(PlaceInformation place) async {
    await _placesRef.doc(place.placeId).set({
      'placeId': place.placeId,
      'name': place.name,
      'address': place.address,
      'lat': place.location!.latitude,
      'lng': place.location!.longitude,
      'createdAt': FieldValue.serverTimestamp(),
      'addedBy': 'user_id_placeholder', // reemplazá con auth si usás
      'mapsTags': place.mapsTags ?? [],
      'extraTags': place.extraTags ?? [],
    });
  }

  /// Elimina un lugar por su placeId
  Future<void> removePlace(String placeId) async {
    await _placesRef.doc(placeId).delete();
  }

  /// Verifica si un lugar ya existe
  Future<bool> placeExists(String placeId) async {
    final doc = await _placesRef.doc(placeId).get();
    return doc.exists;
  }

  /// Trae todos los lugares
  Future<List<PlaceInformation>> getAllPlaces() async {
    final snapshot = await _placesRef.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return PlaceInformation(
        placeId: data['placeId'],
        name: data['name'],
        address: data['address'],
        location: LatLng(data['lat'], data['lng']),
        mapsTags: List<String>.from(data['mapsTags'] ?? []),
        extraTags: List<String>.from(data['extraTags'] ?? []),
      );
    }).toList();
  }
}
