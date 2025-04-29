/// Model representing a Map record in Firestore (collection 'maps').
class MapInfo {
  /// Firestore document ID
  final String? id;
  final String name;
  final String owner;

  MapInfo({
    this.id,
    required this.name,
    this.owner = 'Anonymous',
  });

  /// Deserialize Firestore document into MapInfo
  factory MapInfo.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse 'created_at' if present as a Firestore Timestamp
    return MapInfo(
      id: id,
      name: data['name'] ?? 'Unnamed Map',
      owner: data['owner'] ?? '',
    );
  }

  /// Serialize this MapInfo into a Firestore-compatible map.
  /// Note: 'created_at' is handled server-side via FieldValue.serverTimestamp().
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'owner': owner,
    };
  }
}
