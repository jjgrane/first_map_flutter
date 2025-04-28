import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceInformation {
  final String placeId;
  final String name;
  final String? address;
  final LatLng? location;
  final double? rating;
  final int? totalRatings;
  final String? website;
  final List<String> mapsTags;
  final String? firstPhotoRef;

  PlaceInformation({
    required this.placeId,
    required this.name,
    this.address,
    this.location,
    this.rating,
    this.totalRatings,
    this.website,
    this.mapsTags = const [],
    this.firstPhotoRef,
  });

  // Create a copy with updated fields.
  PlaceInformation copyWith({
    String? name,
    String? address,
    LatLng? location,
    double? rating,
    int? totalRatings,
    String? website,
    List<String>? mapsTags,
    String? firstPhotoRef,
  }) {
    return PlaceInformation(
      placeId: placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      website: website ?? this.website,
      mapsTags: mapsTags ?? this.mapsTags,
      firstPhotoRef: firstPhotoRef ?? this.firstPhotoRef,
    );
  }

  factory PlaceInformation.fromFirestore(Map<String, dynamic> data, String id) {
    GeoPoint? gp = data['geo'] as GeoPoint?;
    LatLng? loc;
    if (gp != null) {
      loc = LatLng(gp.latitude, gp.longitude);
    } else if (data['lat'] != null && data['long'] != null) {
      loc = LatLng(
        (data['lat'] as num).toDouble(),
        (data['long'] as num).toDouble(),
      );
    }
    return PlaceInformation(
      placeId: id,
      name: data['name'] ?? '',
      address: data['address'],
      location: loc,
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      totalRatings: data['totalRatings'] != null ? (data['totalRatings'] as num).toInt() : null,
      website: data['website'],
      mapsTags: List<String>.from(data['mapsTags'] ?? []),
      firstPhotoRef: data['firstPhotoRef'],
    );
  }

  /// Serialize this object to Firestore data for the `place_details` collection.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'geo': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
      'lat': location?.latitude,
      'long': location?.longitude,
      'rating': rating,
      'totalRatings': totalRatings,
      'website': website,
      'first_photo_ref': firstPhotoRef,
      'maps_tags': mapsTags,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  /// Convert this instance into a Google Maps Marker.
  Marker? toMarker() {
    if (location == null) return null;
    return Marker(
      markerId: MarkerId(placeId),
      position: location!,
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure),      
    );
  }
}
