import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/features/markers/marker_icons_service.dart';
import 'package:first_maps_project/features/markers/marker_converter.dart';
import 'package:first_maps_project/features/markers/marker_state_notifier.dart';
import 'package:first_maps_project/services/firebase/firebase_markers_service.dart';

/// Provider for marker icons service
final markerIconsServiceProvider = Provider<MarkerIconsService>((ref) {
  return MarkerIconsService();
});

/// Provider for marker converter service
final markerConverterProvider = Provider<MarkerConverter>((ref) {
  final iconService = ref.watch(markerIconsServiceProvider);
  final onPlaceSelected = ref.watch(selectedPlaceProvider.notifier).update;
  return MarkerConverter(iconService, onPlaceSelected);
});

/// Provider for Firebase markers service
final firebaseMarkersServiceProvider = Provider<FirebaseMarkersService>((ref) {
  return FirebaseMarkersService();
});

/// Provider for the active map (MapInfo)
final activeMapProvider = StateProvider<MapInfo?>((ref) => null);

/// Provider for markers state management
final markersStateProvider = StateNotifierProvider<MarkerStateNotifier, AsyncValue<List<MapMarker>>>((ref) {
  final markersService = ref.watch(firebaseMarkersServiceProvider);
  final activeMap = ref.watch(activeMapProvider);
  return MarkerStateNotifier(markersService, activeMap?.id);
});

/// Provider for the selected place
final selectedPlaceProvider = StateNotifierProvider<SelectedPlaceNotifier, PlaceInformation?>((ref) {
  return SelectedPlaceNotifier();
});

/// Provider for the selected marker
final selectedMarkerProvider = Provider<MapMarker?>((ref) {
  final place = ref.watch(selectedPlaceProvider);
  if (place == null) return null;

  final markersAsync = ref.watch(markersStateProvider);
  
  return markersAsync.when(
    data: (markers) {
      final marker = markers.firstWhere(
        (m) => m.detailsId == place.placeId,
        orElse: () => MapMarker(
          markerId: null,
          detailsId: place.placeId,
          mapId: ref.read(activeMapProvider)?.id ?? '',
          pinIcon: '',
          information: place,
        ),
      );
      return marker;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Notifier for Google Maps markers
class GoogleMapMarkersNotifier extends StateNotifier<AsyncValue<Set<Marker>>> {
  GoogleMapMarkersNotifier() : super(const AsyncValue.data({}));

  void updateMarkers(Set<Marker> markers) {
    state = AsyncValue.data(markers);
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}

/// Provider for Google Maps markers
final googleMapMarkersProvider = StateNotifierProvider<GoogleMapMarkersNotifier, AsyncValue<Set<Marker>>>((ref) {
  return GoogleMapMarkersNotifier();
});

/// Notifier for managing selected place state
class SelectedPlaceNotifier extends StateNotifier<PlaceInformation?> {
  SelectedPlaceNotifier() : super(null);

  void update(PlaceInformation place) {
    state = place;
  }

  void clear() {
    state = null;
  }
} 