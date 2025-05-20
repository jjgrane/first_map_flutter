import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/services/maps/emoji_marker_converter.dart';

/// Service to manage Marker records in Firestore.
/// Collection: 'markers'
class FirebaseMarkersService {
  final CollectionReference _markersRef =
      FirebaseFirestore.instance.collection('markers');
  
  final CollectionReference _groupsRef =
      FirebaseFirestore.instance.collection('groups');

  /// Adds a new MapMarker document in 'markers'.
  Future<String> addMarker(MapMarker marker) async {
    try {
      final docRef = await _markersRef.add(marker.toFirestore());
      return docRef.id;
    } catch (error) {
      print('Error adding marker: $error');
      rethrow;
    }
  }

  /// Deletes a marker by its ID.
  Future<void> removeMarker(String markerId) async {
    try {
      await _markersRef.doc(markerId).delete();
    } catch (error) {
      print('Error removing marker $markerId: $error');
      rethrow;
    }
  }

  /// Checks if a marker exists by its ID.
  Future<bool> markerExists(String markerId) async {
    try {
      final doc = await _markersRef.doc(markerId).get();
      return doc.exists;
    } catch (error) {
      print('Error checking marker existence $markerId: $error');
      rethrow;
    }
  }

  /// Retrieves all markers
  Future<List<MapMarker>> getAllMarkers() async {
    try {
      final snapshot = await _markersRef.get();
      final futures = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MapMarker.fromFirestoreWithDetails(data, doc.id);
      });
      return Future.wait(futures);
    } catch (error) {
      print('Error getting all markers: $error');
      rethrow;
    }
  }

  /// Retrieves a single MapMarker by its ID, or null if not found
  Future<MapMarker?> getMarkerById(String markerId) async {
    try {
      final doc = await _markersRef.doc(markerId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return MapMarker.fromFirestoreWithDetails(data, doc.id);
    } catch (error) {
      print('Error getting marker $markerId: $error');
      rethrow;
    }
  }

  /// Retrieves all markers associated with a given mapId
  Future<List<MapMarker>> getMarkersByMapId(String mapId) async {
    try {
      // First, get all groups for this map to prepare the icons
      final groupsSnapshot = await _groupsRef
          .where('map_id', isEqualTo: mapId)
          .get();
      
      // Clear previous emoji cache
      EmojiMarkerConverter.clearCache();
      
      // If there are groups, preload their emojis
      if (groupsSnapshot.docs.isNotEmpty) {
        final emojis = groupsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .map((data) => data['emoji'] as String)
            .toList();
        
        await EmojiMarkerConverter.preloadEmojis(emojis);
      }

      // Now get the markers
      final snapshot = await _markersRef
          .where('map_id', isEqualTo: mapId)
          .get();
    
      final futures = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MapMarker.fromFirestoreWithDetails(data, doc.id);
      });

      return await Future.wait(futures);
    } catch (error) {
      print('Error loading markers for map $mapId: $error');
      rethrow;
    }
  }

  /// Updates a marker
  Future<void> updateMarker(MapMarker marker) async {
    if (marker.markerId == null) {
      throw ArgumentError('Cannot update a marker without an ID');
    }
    try {
      await _markersRef.doc(marker.markerId!).update(marker.toFirestore());
    } catch (error) {
      print('Error updating marker ${marker.markerId}: $error');
      rethrow;
    }
  }

  /// Updates a marker's group assignment
  Future<void> updateMarkerGroup(String markerId, String? groupId) async {
    try {
      await _markersRef.doc(markerId).update({
        'group_id': groupId,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error updating marker group for marker $markerId: $error');
      rethrow;
    }
  }

  /// Get all markers in a specific group
  Future<List<MapMarker>> getMarkersByGroupId(String groupId) async {
    try {
      final snapshot = await _markersRef
          .where('group_id', isEqualTo: groupId)
          .get();
      
      final futures = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MapMarker.fromFirestoreWithDetails(data, doc.id);
      });

      return await Future.wait(futures);
    } catch (error) {
      print('Error getting markers for group $groupId: $error');
      rethrow;
    }
  }
}
