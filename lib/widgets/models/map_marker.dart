import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/place_information.dart'; 
import 'package:first_maps_project/services/firebase_markers_service.dart';

class MapMarker {
  final String? markerId;
  final String detailsId;
  final String mapId;
  final PlaceInformation? information;

  MapMarker({
    this.markerId,
    required this.detailsId,
    required this.mapId,
    this.information,
  });

  Marker? toMarker() {
    if (markerId == null || information?.location == null) return null;
    return Marker(
      markerId: MarkerId(markerId!),
      position: information!.location!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  factory MapMarker.fromFirestore(Map<String, dynamic> data, String id) {
    return MapMarker(
      markerId: id,
      detailsId: data['details_id'] as String,
      mapId: data['map_id'] as String,
    );
  }

  /// Convert Firestore data into a MapMarker
  Map<String, dynamic> toFirestore() {
    return {
      'details_id': detailsId,
      'map_id': mapId,
      'addedBy':'anonymous', 
    };
  }

    Future<MapMarker> save(FirebaseMarkersService svc) async {
    // 1) Write the bare data (without an ID) and get back the new doc ID:
    final newId = await svc.addMarker(this);
    // 2) Return a new instance that carries that ID:
    return MapMarker(
      markerId: newId,
      detailsId: detailsId,
      mapId: mapId,
      information: information,
    );
  }

}
