import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/services/firebase/firebase_markers_service.dart';

/// State notifier for managing map markers
class MarkerStateNotifier extends StateNotifier<AsyncValue<List<MapMarker>>> {
  final FirebaseMarkersService _markersService;
  final String? mapId;

  MarkerStateNotifier(this._markersService, this.mapId) : super(const AsyncValue.loading()) {
    if (mapId != null) {
      loadMarkers();
    }
  }

  /// Load markers for the current map
  Future<void> loadMarkers() async {
    if (mapId == null) {
      print('MarkerStateNotifier - No mapId provided, returning empty list');
      state = const AsyncValue.data([]);
      return;
    }

    try {
      print('MarkerStateNotifier - Loading markers for mapId: $mapId');
      state = const AsyncValue.loading();
      
      final markers = await _markersService.getMarkersByMapId(mapId!);
      print('MarkerStateNotifier - Loaded ${markers.length} markers successfully');
      
      state = AsyncValue.data(markers);
    } catch (error, stackTrace) {
      print('MarkerStateNotifier - Error loading markers: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a new marker
  Future<void> addMarker(MapMarker marker) async {
    try {
      final markerId = await _markersService.addMarker(marker);
      final updatedMarker = marker.copyWith(markerId: markerId);
      
      state.whenData((markers) {
        state = AsyncValue.data([...markers, updatedMarker]);
      });
    } catch (error, stackTrace) {
      print('MarkerStateNotifier - addMarker - Error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Remove a marker
  Future<void> removeMarker(String markerId) async {
    try {
      await _markersService.removeMarker(markerId);
      
      state.whenData((markers) {
        state = AsyncValue.data(
          markers.where((m) => m.markerId != markerId).toList(),
        );
      });
    } catch (error, stackTrace) {
      print('MarkerStateNotifier - removeMarker - Error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update an existing marker
  Future<void> updateMarker(MapMarker marker) async {
    try {
      await _markersService.updateMarker(marker);
      
      state.whenData((markers) {
        final updatedMarkers = markers.map((m) => 
          m.markerId == marker.markerId ? marker : m
        ).toList();
        state = AsyncValue.data(updatedMarkers);
      });
    } catch (error, stackTrace) {
      print('MarkerStateNotifier - updateMarker - Error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 