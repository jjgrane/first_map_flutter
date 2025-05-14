import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/place_information.dart'; 
import 'package:first_maps_project/services/firebase/firebase_markers_service.dart';
import 'package:first_maps_project/services/firebase_places_details_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapMarker {
  final String? markerId;
  final String detailsId;
  final String mapId;
  final PlaceInformation? information;
  final String pinIcon;

  MapMarker({
    this.markerId,
    required this.detailsId,
    required this.mapId,
    this.information,
    required this.pinIcon,
  });

  /// Creates a copy of this MapMarker with the given fields replaced with the new values
  MapMarker copyWith({
    String? markerId,
    String? detailsId,
    String? mapId,
    PlaceInformation? information,
    String? pinIcon,
  }) {
    return MapMarker(
      markerId: markerId ?? this.markerId,
      detailsId: detailsId ?? this.detailsId,
      mapId: mapId ?? this.mapId,
      information: information ?? this.information,
      pinIcon: pinIcon ?? this.pinIcon,
    );
  }

  Marker? toMarker(void Function(PlaceInformation) onPlaceSelected, BitmapDescriptor icon) {
    if (markerId == null || information?.location == null) return null;
    return Marker(
      markerId: MarkerId(markerId!),
      position: information!.location!,
      icon: icon,
      onTap: () => onPlaceSelected(information!),
    );
  }

  factory MapMarker.fromFirestore(Map<String, dynamic> data, String id) {
    return MapMarker(
      markerId: id,
      detailsId: data['details_id'] as String,
      mapId: data['map_id'] as String,
      pinIcon: data['pin_icon'] as String,
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
      'pin_icon': pinIcon,
      'added_by': 'anonymous',
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

    Future<MapMarker> save(FirebaseMarkersService svc) async {
    // 1) Write the bare data (without an ID) and get back the new doc ID:
    final newId = await svc.addMarker(this);
    // 2) Return a new instance that carries that ID:
    MapMarker marker =  MapMarker(
      markerId: newId,
      detailsId: detailsId,
      mapId: mapId,
      information: information,
      pinIcon: pinIcon,
    );
  /*
    print("SE ENTRO A ESTA FUNCION");
    await http.post(
      Uri.parse('http://192.168.0.107:8080/echo'), // Cambia el endpoint según tu backend
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(marker),
    );
  */


    return marker;
  }

}
