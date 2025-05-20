 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';

/// Service to manage Map records in Firestore.
/// Collection: 'maps'
class FirebaseMapsService {
  final CollectionReference _mapsRef =
      FirebaseFirestore.instance.collection('maps');

  /// Adds a new map with the given [mapInfo], letting Firestore generate the ID,
  /// and returns the new MapInfo (with its assigned id).
  Future<MapInfo> addMap(MapInfo mapInfo) async {
    final docRef = await _mapsRef.add({
      ...mapInfo.toFirestore(),
      'created_at': FieldValue.serverTimestamp(),
    });
    // Rebuild a MapInfo with the new ID
    return MapInfo(id: docRef.id, name: mapInfo.name, owner: mapInfo.owner);
  }

  /// Updates an existing map (merges fields).
  Future<void> updateMap(MapInfo mapInfo) async {
    await _mapsRef.doc(mapInfo.id).set(
      mapInfo.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Deletes a map by its ID.
  Future<void> removeMap(String mapId) async {
    await _mapsRef.doc(mapId).delete();
  }

  /// Checks if a map exists by its ID.
  Future<bool> mapExists(String mapId) async {
    final doc = await _mapsRef.doc(mapId).get();
    return doc.exists;
  }

  /// Retrieves all maps in the collection.
  Future<List<MapInfo>> getAllMaps() async {
    final snapshot = await _mapsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MapInfo.fromFirestore(data, doc.id);
    }).toList();
  }

  /// Retrieves a single map by its ID, or null if not found.
  Future<MapInfo?> getMapById(String mapId) async {
    final doc = await _mapsRef.doc(mapId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return MapInfo.fromFirestore(data, doc.id);
  }
}
