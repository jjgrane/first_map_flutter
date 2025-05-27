import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/services/maps/emoji_marker_converter.dart';
import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';

class GoogleMapsPinsService {
  Set<Marker> _currentMarkers = {};
  MapMarker? _currentSelectedMarker;

  GoogleMapsPinsService();

  /// Inicializa los marcadores desde el estado actual
  Future<Set<Marker>> initializeMarkers(
    List<MapMarker> stateMarkers,
    MapMarker? selectedMarker,
    List<Group> groups,
    Ref ref,
  ) async {
    _currentMarkers = await _convertMarkersToGoogleMarkers(stateMarkers, groups, ref, selectedMarker: selectedMarker);
    _currentSelectedMarker = selectedMarker;
    return _currentMarkers;
  }

  /// Actualiza el marcador seleccionado de forma eficiente y clara
  Future<Set<Marker>> updateSelectedMarker(
    List<MapMarker> stateMarkers,
    MapMarker? newSelectedMarker,
    List<Group> groups,
    Ref ref,
  ) async {
    final bool isNewSelectedSaved = newSelectedMarker != null &&
        newSelectedMarker.markerId != null &&
        stateMarkers.any((m) => m.markerId == newSelectedMarker.markerId);

    final bool wasSelectedExternal = _currentSelectedMarker != null &&
        _currentSelectedMarker!.markerId == null;

    final bool isNewSelectedExternal = newSelectedMarker != null &&
        newSelectedMarker.markerId == null;

    if (isNewSelectedSaved) {
      if (wasSelectedExternal) {
        _currentMarkers.removeWhere(
          (m) => m.markerId.value == _currentSelectedMarker!.markerId,
        );
      }
    } else if (isNewSelectedExternal) {
      if (wasSelectedExternal) {
        _currentMarkers.removeWhere(
          (m) => m.markerId.value == _currentSelectedMarker!.markerId,
        );
      }
      final externalMarker = await createGoogleMarker(newSelectedMarker!, groups, ref: ref, isSelected: true);
      _currentMarkers.add(externalMarker);
    } else if (newSelectedMarker == null) {
      if (wasSelectedExternal) {
        _currentMarkers.removeWhere(
          (m) => m.markerId.value == _currentSelectedMarker!.markerId,
        );
      }
    }

    _currentSelectedMarker = newSelectedMarker;
    return _currentMarkers;
  }

  /// Convierte una lista de marcadores a marcadores de Google Maps
  Future<Set<Marker>> _convertMarkersToGoogleMarkers(
    List<MapMarker> markers,
    List<Group> groups,
    Ref ref, {
    MapMarker? selectedMarker,
  }) async {
    final Set<Marker> googleMarkers = {};

    for (final marker in markers) {
      final isSelected = marker == selectedMarker;
      // Usar el googleMarker ya creado si existe y no es el seleccionado
      if (marker.googleMarker != null && !isSelected) {
        googleMarkers.add(marker.googleMarker!);
      } else {
        final googleMarker = await createGoogleMarker(marker, groups, ref: ref, isSelected: isSelected);
        googleMarkers.add(googleMarker);
      }
    }

    return googleMarkers;
  }

  /// Crea un marcador de Google Maps a partir de un MapMarker
  Future<Marker> createGoogleMarker(
    MapMarker marker,
    List<Group> groups, {
    required Ref ref,
    bool isSelected = false,
  }) async {
    if (marker.information?.location == null) {
      throw Exception('Cannot create marker without location');
    }

    BitmapDescriptor icon;
    if (marker.groupId != null) {
      final group = groups.firstWhere(
        (g) => g.id == marker.groupId,
        orElse: () => Group(id: null, mapId: '', emoji: '', name: ''),
      );
      if (group.emoji.isNotEmpty) {
        icon = await group.getMarkerIcon(
          size: isSelected ? 120 : 100,
          borderColor: isSelected ? Colors.blue : Colors.black,
          borderWidth: isSelected ? 3 : 2,
        );
      } else {
        icon = BitmapDescriptor.defaultMarker;
      }
    } else {
      icon = BitmapDescriptor.defaultMarker;
    }

    return Marker(
      markerId: MarkerId(marker.markerId ?? 'unknown'),
      position: marker.information!.location!,
      icon: icon,
      zIndex: isSelected ? 2 : 1,
      onTap: () {
        if (marker.information != null) {
          ref.read(selectedPlaceProvider.notifier).update(marker.information!);
        }
      },
    );
  }
} 