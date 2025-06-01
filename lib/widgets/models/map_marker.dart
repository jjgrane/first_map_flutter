import 'package:first_maps_project/widgets/models/place_information.dart'; 
import 'package:first_maps_project/services/firebase/maps/firebase_markers_service.dart';
import 'package:first_maps_project/services/firebase/places/firebase_places_details_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarker {
  final String? markerId;
  final String detailsId;
  final String mapId;
  final PlaceInformation? information;
  final String? groupId;
  final Marker? googleMarker;
  

  MapMarker({
    this.markerId,
    required this.detailsId,
    required this.mapId,
    this.information,
    this.groupId,
    this.googleMarker,
  });

  /// Creates a copy of this MapMarker with the given fields replaced with the new values
  MapMarker copyWith({
    String? markerId,
    String? detailsId,
    String? mapId,
    PlaceInformation? information,
    String? groupId,
    Marker? googleMarker,
  }) {
    return MapMarker(
      markerId: markerId ?? this.markerId,
      detailsId: detailsId ?? this.detailsId,
      mapId: mapId ?? this.mapId,
      information: information ?? this.information,
      groupId: groupId ?? this.groupId,
      googleMarker: googleMarker ?? this.googleMarker,
    );
  }

  factory MapMarker.fromFirestore(Map<String, dynamic> data, String id) {
    return MapMarker(
      markerId: id,
      detailsId: data['details_id'] as String,
      mapId: data['map_id'] as String,
      groupId: data['group_id'] as String?,
      information: null,
      googleMarker: null,
    );
  }

  /// Creates a MapMarker from JSON (REST API)
  factory MapMarker.fromJson(Map<String, dynamic> json) {
    PlaceInformation? info;
    if (json['information'] != null) {
      info = PlaceInformation.fromJson(json['information']);
    }
    
    return MapMarker(
      markerId: json['marker_id'] as String?,
      detailsId: json['details_id'] as String,
      mapId: json['map_id'] as String,
      groupId: json['group_id'] as String?,
      information: info,
      googleMarker: null, // Runtime-only field, not serialized
    );
  }

  /// Converts MapMarker to JSON (REST API)
  Map<String, dynamic> toJson() {
    return {
      if (markerId != null) 'marker_id': markerId,
      'details_id': detailsId,
      'map_id': mapId,
      if (groupId != null) 'group_id': groupId,
      if (information != null) 'information': information!.toJson(),
    };
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
