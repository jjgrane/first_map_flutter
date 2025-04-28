import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';

/// Service to manage Marker records in Firestore.
/// Collection: 'markers'
class FirebaseMarkersService {
  final CollectionReference _markersRef =
      FirebaseFirestore.instance.collection('markers');

  /// Adds a new MapMarker document in 'markers'.
  /// Uses [marker.markerId] as the document ID.
  Future<String> addMarker(MapMarker marker) async {
    // Instead of .doc(marker.markerId).set(…) we let Firestore pick the ID:
    final docRef = await _markersRef.add(marker.toFirestore());
    return docRef.id;
  }

  /// Deletes a marker by its ID.
  Future<void> removeMarker(String markerId) async {
    await _markersRef.doc(markerId).delete();
  }

  /// Checks if a marker exists by its ID.
  Future<bool> markerExists(String markerId) async {
    final doc = await _markersRef.doc(markerId).get();
    return doc.exists;
  }

  /// Retrieves all markers
  Future<List<MapMarker>> getAllMarkers() async {
    final snapshot = await _markersRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MapMarker.fromFirestore(data, doc.id);
    }).toList();
  }

  /// Retrieves a single MapMarker by its ID, or null if not found
  Future<MapMarker?> getMarkerById(String markerId) async {
    final doc = await _markersRef.doc(markerId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return MapMarker.fromFirestore(data, doc.id);
  }

  /// Retrieves all markers associated with a given mapId
  Future<List<MapMarker>> getMarkersByMapId(String mapId) async {
    final snapshot = await _markersRef
        .where('map_id', isEqualTo: mapId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MapMarker.fromFirestore(data, doc.id);
    }).toList();
  }
}
