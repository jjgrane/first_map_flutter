import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/features/markers/marker_icons_service.dart';

/// Service responsible for converting MapMarker objects to Google Maps Markers
class MarkerConverter {
  final MarkerIconsService _iconService;
  final void Function(PlaceInformation) _onPlaceSelected;

  MarkerConverter(this._iconService, this._onPlaceSelected);

  /// Convert a list of MapMarkers to a Set of Google Maps Markers
  Future<Set<Marker>> convertToGoogleMarkers(
    List<MapMarker> markers, {
    MapMarker? selectedMarker,
  }) async {
    final Set<Marker> markerSet = {};

    // Add regular markers
    for (final marker in markers) {
      if (marker.information?.location != null) {
        final icon = await _iconService.getOrCreateIcon(marker.pinIcon);
        markerSet.add(
          Marker(
            markerId: MarkerId(marker.markerId ?? 'unknown'),
            position: marker.information!.location!,
            icon: icon,
            onTap: () => _onPlaceSelected(marker.information!),
            zIndex: 1,
          ),
        );
      }
    }

    // Add selected marker with different style if it exists
    if (selectedMarker?.information?.location != null) {
      final icon = await _iconService.getOrCreateIcon(selectedMarker!.pinIcon);
      markerSet.add(
        Marker(
          markerId: MarkerId(selectedMarker.markerId ?? 'unknown'),
          position: selectedMarker.information!.location!,
          icon: icon,
          onTap: () => _onPlaceSelected(selectedMarker.information!),
          zIndex: 2, // Ensure selected marker appears on top
        ),
      );
    }

    return markerSet;
  }

  /// Convert a single MapMarker to a Google Maps Marker
  Future<Marker?> convertToGoogleMarker(MapMarker marker) async {
    if (marker.information?.location == null) return null;

    final icon = await _iconService.getOrCreateIcon(marker.pinIcon);
    return Marker(
      markerId: MarkerId(marker.markerId ?? 'unknown'),
      position: marker.information!.location!,
      icon: icon,
      onTap: () => _onPlaceSelected(marker.information!),
      zIndex: 1,
    );
  }
} 