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
    final futures = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MapMarker.fromFirestoreWithDetails(data, doc.id);
    });
    return Future.wait(futures);
  }

  /// Retrieves a single MapMarker by its ID, or null if not found
  Future<MapMarker?> getMarkerById(String markerId) async {
    final doc = await _markersRef.doc(markerId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return MapMarker.fromFirestoreWithDetails(data, doc.id);
  }

  /// Retrieves all markers associated with a given mapId
  Future<List<MapMarker>> getMarkersByMapId(String mapId) async {
    print('FirebaseMarkersService - Requesting markers for mapId: $mapId');
    
    try {
      final snapshot = await _markersRef
          .where('map_id', isEqualTo: mapId)
          .get();
      
      print('FirebaseMarkersService - Received ${snapshot.docs.length} markers from Firebase');
    
      final futures = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('FirebaseMarkersService - Converting marker: ${doc.id} with data: $data');
        return MapMarker.fromFirestoreWithDetails(data, doc.id);
      });

      final markers = await Future.wait(futures);
      print('FirebaseMarkersService - Successfully converted ${markers.length} markers');
      return markers;
    } catch (error) {
      print('FirebaseMarkersService - Error fetching markers: $error');
      rethrow;
    }
  }

  Future<void> updateMarker(MapMarker marker) async {
    if (marker.markerId == null) {
      throw ArgumentError('Cannot update a marker without an ID');
    }
    await _markersRef.doc(marker.markerId!).update({
      'pin_icon': marker.pinIcon,
      // If you want to track when it was updated:
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
} 