import 'package:first_maps_project/widgets/models/place_information.dart'; 
import 'package:first_maps_project/services/firebase/maps/firebase_markers_service.dart';
import 'package:first_maps_project/services/firebase/places/firebase_places_details_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapMarker {
  final String? markerId;
  final String detailsId;
  final String mapId;
  final PlaceInformation? information;
  final String? groupId;

  MapMarker({
    this.markerId,
    required this.detailsId,
    required this.mapId,
    this.information,
    this.groupId,
  });

  /// Creates a copy of this MapMarker with the given fields replaced with the new values
  MapMarker copyWith({
    String? markerId,
    String? detailsId,
    String? mapId,
    PlaceInformation? information,
    String? groupId,
  }) {
    return MapMarker(
      markerId: markerId ?? this.markerId,
      detailsId: detailsId ?? this.detailsId,
      mapId: mapId ?? this.mapId,
      information: information ?? this.information,
      groupId: groupId ?? this.groupId,
    );
  }

  factory MapMarker.fromFirestore(Map<String, dynamic> data, String id) {
    return MapMarker(
      markerId: id,
      detailsId: data['details_id'] as String,
      mapId: data['map_id'] as String,
      groupId: data['group_id'] as String?,
      information: null,
    );
  }

  /// Creates a MapMarker from Firestore data and loads its place information
  static Future<MapMarker> fromFirestoreWithDetails(Map<String, dynamic> data, String id) async {
    final marker = MapMarker.fromFirestore(data, id);
    final placeDetailsService = FirebasePlaceDetailsService();
    final placeInfo = await placeDetailsService.getPlaceDetailsById(marker.detailsId);
    
    return marker.copyWith(information: placeInfo);
  }

  /// Convert Firestore data into a MapMarker
  Map<String, dynamic> toFirestore() {
    return {
      'details_id': detailsId,
      'map_id': mapId,
      'group_id': groupId,
      'added_by': 'anonymous',
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Future<MapMarker> save(FirebaseMarkersService svc) async {
    final newId = await svc.addMarker(this);
    return copyWith(markerId: newId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarker &&
          runtimeType == other.runtimeType &&
          markerId == other.markerId &&
          detailsId == other.detailsId &&
          mapId == other.mapId &&
          groupId == other.groupId;

  @override
  int get hashCode =>
      markerId.hashCode ^
      detailsId.hashCode ^
      mapId.hashCode ^
      groupId.hashCode;

  @override
  String toString() {
    return 'MapMarker{markerId: $markerId, detailsId: $detailsId, mapId: $mapId, groupId: $groupId}';
  }
}
