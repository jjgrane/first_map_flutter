import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceInformation {
  final String placeId;
  final String name;
  final String? address;
  final LatLng? location;

  PlaceInformation({
    required this.placeId,
    required this.name,
    this.address,
    this.location,
  });

  // esta funcion sirve para actualizar atributos del objeto
  PlaceInformation copyWith({
    String? name,
    String? placeId,
    String? address,
    LatLng? location,
  }) {
    return PlaceInformation(
      name: name ?? this.name,
      placeId: placeId ?? this.placeId,
      address: address ?? this.address,
      location: location ?? this.location,
    );
  }

  Marker? toMarker() {
    if (location == null) return null;

    return Marker(
      markerId: MarkerId(placeId),
      position: location!,
      infoWindow: InfoWindow(title: name, snippet: address),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }
}
