import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/services/maps/places_service.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_maps_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Manages map controller and map-related logic for the app.
class MapManager {
  GoogleMapController? mapController;
  final PlacesService _placesService;
  final FirebaseMapsService _mapsService;

  MapManager({this.mapController})
      : _placesService = PlacesService(dotenv.env['GOOGLE_MAPS_API_KEY']!),
        _mapsService = FirebaseMapsService();

  PlacesService get placesService => _placesService;

  /// Called when the GoogleMap is created.
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// Returns the current center of the visible map region.
  Future<LatLng?> getCameraCenter() async {
    if (mapController == null) return null;
    final bounds = await mapController!.getVisibleRegion();
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  /// Handles selection of a place marker on the map. Returns the selected place.
  PlaceInformation selectPlace(PlaceInformation place) {
    // This method can be expanded to handle marker logic if needed
    return place;
  }

  /// Handles selection of a place from search or elsewhere.
  /// Fetches place details if needed, animates camera, and returns the updated place.
  Future<PlaceInformation?> handlePlaceSelected(
    PlaceInformation place,
    String? sessionToken,
  ) async {
    PlaceInformation? updatedPlace = place;
    if (place.location == null) {
      updatedPlace = await _placesService.getPlaceDetails(
        place.placeId,
        sessionToken,
      );
    }
    if (updatedPlace == null) {
      return null;
    }
    final coords = updatedPlace.location;
    if (coords != null && mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
    }
    return updatedPlace;
  }

  /// Loads the default map from the backend and returns it.
  Future<MapInfo?> loadDefaultMap() async {
    final maps = await _mapsService.getAllMaps();
    final def = maps.firstWhere(
      (m) => m.name == 'default',
      orElse: () => MapInfo(id: '', name: '', owner: ''),
    );
    if (def.id!.isEmpty) return null;
    return def;
  }

  void moveTo(LatLng target, {double zoom = 15}) {
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }
} 