import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceInformation {
  final String placeId;
  final String name;
  final String? address;
  final String? formattedAddress;
  final LatLng? location;
  final List<String>? mapsTags;
  final List<String>? extraTags;
  final String? firstPhotoRef;

  PlaceInformation({
    required this.placeId,
    required this.name,
    this.address,
    this.formattedAddress,
    this.location,
    this.mapsTags = const [],
    this.extraTags = const [],
    this.firstPhotoRef,
  });

  // esta funcion sirve para actualizar atributos del objeto
  PlaceInformation copyWith({
    String? name,
    String? placeId,
    String? address,
    String? formattedAddress,
    LatLng? location,
    List<String>? mapsTags,
    List<String>? extraTags,
    String? firstPhotoRef,
  }) {
    return PlaceInformation(
      name: name ?? this.name,
      placeId: placeId ?? this.placeId,
      address: address ?? this.address,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      location: location ?? this.location,
      mapsTags: mapsTags ?? this.mapsTags,
      extraTags: extraTags ?? this.extraTags,
      firstPhotoRef: firstPhotoRef ?? this.firstPhotoRef,
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

  factory PlaceInformation.fromFirestore(Map<String, dynamic> data, String id) {
    return PlaceInformation(
      placeId: id,
      name: data['name'] ?? '',
      firstPhotoRef: data['firstPhotoRef'],
      address: data['address'],
      location: LatLng(data['lat'], data['long']),
      mapsTags: List<String>.from(data['mapsTags'] ?? []),
      extraTags: List<String>.from(data['extraTags'] ?? []),
      // otros campos...
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'firstPhotoRef': firstPhotoRef,
      'lat': location?.latitude,
      'long': location?.longitude,
      'geo':
          location != null
              ? GeoPoint(location!.latitude, location!.longitude)
              : null,
      'mapsTags': mapsTags ?? [],
      'extraTags': extraTags ?? [],
      'createdAt': DateTime.now().toIso8601String(),
      'addedBy':
          'anonymous', // o podés reemplazarlo con el UID de Firebase Auth si usás auth
    };
  }
}
