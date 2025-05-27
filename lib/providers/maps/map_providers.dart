import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/services/maps/emoji_marker_converter.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_markers_service.dart';
import 'package:first_maps_project/services/firebase/groups/firebase_groups_service.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/services/maps/google_maps_pins_service.dart';
import 'package:flutter/foundation.dart';

// =============================================================================
// Service Providers
// =============================================================================

final markerConverterProvider = Provider<EmojiMarkerConverter>((ref) {
  return EmojiMarkerConverter();
});

final firebaseMarkersServiceProvider = Provider<FirebaseMarkersService>((ref) {
  return FirebaseMarkersService();
});

final googleMapsPinsServiceProvider = Provider<GoogleMapsPinsService>((ref) {
  return GoogleMapsPinsService();
});

// =============================================================================
// Active Map Provider
// =============================================================================

class ActiveMapNotifier extends StateNotifier<MapInfo?> {
  ActiveMapNotifier() : super(null);

  void setActiveMap(MapInfo map) => state = map;
  void clearActiveMap() => state = null;
}

final activeMapProvider = StateNotifierProvider<ActiveMapNotifier, MapInfo?>((ref) {
  return ActiveMapNotifier();
});

// =============================================================================
// Markers State Management
// =============================================================================

class MarkerNotifier extends StateNotifier<AsyncValue<List<MapMarker>>> {
  final Ref ref;
  final FirebaseMarkersService _markersService;
  final String? mapId;

  MarkerNotifier(this.ref, this._markersService, this.mapId) : super(const AsyncValue.loading());

  Future<void> loadMarkers() async {
    if (mapId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final markers = await _markersService.getMarkersByMapId(mapId!);
      // Enriquecer cada MapMarker con su googleMarker
      final groups = ref.read(groupsStateProvider).maybeWhen(
        data: (g) => g,
        orElse: () => <Group>[],
      );
      final pinsService = ref.read(googleMapsPinsServiceProvider);
      final List<MapMarker> enrichedMarkers = [];
      for (final marker in markers) {
        final googleMarker = await pinsService.createGoogleMarker(marker, groups, ref: ref);
        enrichedMarkers.add(marker.copyWith(googleMarker: googleMarker));
      }
      state = AsyncValue.data(enrichedMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMarker(MapMarker marker) async {
    try {
      final markerId = await _markersService.addMarker(marker);
      final updatedMarker = marker.copyWith(markerId: markerId);
      // Enriquecer con googleMarker
      final groups = ref.read(groupsStateProvider).maybeWhen(
        data: (g) => g,
        orElse: () => <Group>[],
      );
      final pinsService = ref.read(googleMapsPinsServiceProvider);
      final googleMarker = await pinsService.createGoogleMarker(updatedMarker, groups, ref: ref);
      final enrichedMarker = updatedMarker.copyWith(googleMarker: googleMarker);
      state.whenData((markers) {
        state = AsyncValue.data([...markers, enrichedMarker]);
      });
      ref.read(googleMapMarkersProvider.notifier).addMarker(enrichedMarker, groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeMarker(String markerId) async {
    try {
      await _markersService.removeMarker(markerId);
      state.whenData((markers) {
        state = AsyncValue.data(
          markers.where((m) => m.markerId != markerId).toList(),
        );
      });
      ref.read(googleMapMarkersProvider.notifier).removeMarker(markerId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMarker(MapMarker marker) async {
    try {
      await _markersService.updateMarker(marker);
      // Enriquecer con googleMarker
      final groups = ref.read(groupsStateProvider).maybeWhen(
        data: (g) => g,
        orElse: () => <Group>[],
      );
      final pinsService = ref.read(googleMapsPinsServiceProvider);
      final googleMarker = await pinsService.createGoogleMarker(marker, groups, ref: ref);
      final enrichedMarker = marker.copyWith(googleMarker: googleMarker);
      state.whenData((markers) {
        final updatedMarkers = markers.map((m) => 
          m.markerId == marker.markerId ? enrichedMarker : m
        ).toList();
        state = AsyncValue.data(updatedMarkers);
      });
      ref.read(googleMapMarkersProvider.notifier).updateMarker(enrichedMarker, groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final markersStateProvider = StateNotifierProvider<MarkerNotifier, AsyncValue<List<MapMarker>>>((ref) {
  final markersService = ref.watch(firebaseMarkersServiceProvider);
  final activeMap = ref.watch(activeMapProvider);
  return MarkerNotifier(ref, markersService, activeMap?.id);
});

// =============================================================================
// Groups State Management
// =============================================================================

class GroupsNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  final FirebaseGroupsService _groupsService;
  final String? mapId;

  GroupsNotifier(this._groupsService, this.mapId) : super(const AsyncValue.loading()) {
    if (mapId != null) loadGroups();
  }

  Future<void> loadGroups() async {
    if (mapId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final groups = await _groupsService.getGroupsByMapId(mapId!);
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String> addGroupAndReturnId(Group group) async {
    try {
      final groupId = await _groupsService.addGroup(group);
      final updatedGroup = group.copyWith(id: groupId);
      state.whenData((groups) {
        state = AsyncValue.data([...groups, updatedGroup]);
      });
      return groupId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> removeGroup(String groupId) async {
    try {
      await _groupsService.removeGroup(groupId);
      state.whenData((groups) {
        state = AsyncValue.data(
          groups.where((g) => g.id != groupId).toList(),
        );
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateGroup(Group group, Ref ref) async {
    try {
      // 1. Obtener el grupo anterior para comparar el emoji
      Group? previousGroup;
      state.whenData((groups) {
        previousGroup = null;
        for (final g in groups) {
          if (g.id == group.id) {
            previousGroup = g;
            break;
          }
        }
      });

      await _groupsService.updateGroup(group);
      // Actualizar el estado de grupos
      state.whenData((groups) {
        final updatedGroups = groups.map((g) => g.id == group.id ? group : g).toList();
        state = AsyncValue.data(updatedGroups);
      });

      // 2. Si el emoji cambió, actualizar los markers asociados
      if (previousGroup != null && previousGroup!.emoji != group.emoji) {
        // Obtener la lista de markers y grupos actualizada
        final markers = ref.read(markersStateProvider).maybeWhen(
          data: (m) => m,
          orElse: () => <MapMarker>[],
        );
        final groups = ref.read(groupsStateProvider).maybeWhen(
          data: (g) => g,
          orElse: () => <Group>[],
        );
        final pinsService = ref.read(googleMapsPinsServiceProvider);

        // Enriquecer todos los markers afectados
        final List<MapMarker> updatedMarkers = [];
        for (final marker in markers) {
          if (marker.groupId == group.id) {
            final googleMarker = await pinsService.createGoogleMarker(marker, groups, ref: ref);
            updatedMarkers.add(marker.copyWith(googleMarker: googleMarker));
          } else {
            updatedMarkers.add(marker);
          }
        }

        // Actualizar el estado de markers en batch
        ref.read(markersStateProvider.notifier).state = AsyncValue.data(updatedMarkers);

        // Refrescar el set de Google Markers
        ref.read(googleMapMarkersProvider.notifier).initialize(
          updatedMarkers,
          ref.read(selectedMarkerProvider),
          groups,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void toggleGroupActive(String groupId) {
    state.whenData((groups) {
      final updatedGroups = groups.map((g) =>
        g.id == groupId ? g.copyWith(active: !g.active) : g
      ).toList();
      print('Toggling group $groupId. New actives: '
        '${updatedGroups.map((g) => '${g.name}:${g.active}').join(', ')}');
      state = AsyncValue.data(updatedGroups);
    });
  }
}

final groupsStateProvider = StateNotifierProvider<GroupsNotifier, AsyncValue<List<Group>>>((ref) {
  final groupsService = FirebaseGroupsService();
  final activeMap = ref.watch(activeMapProvider);
  return GroupsNotifier(groupsService, activeMap?.id);
});

// =============================================================================
// Selected Place & Marker Management
// =============================================================================

class SelectedPlaceNotifier extends StateNotifier<PlaceInformation?> {
  SelectedPlaceNotifier() : super(null);

  void update(PlaceInformation place) => state = place;
  void clear() => state = null;
}

final selectedPlaceProvider = StateNotifierProvider<SelectedPlaceNotifier, PlaceInformation?>((ref) {
  return SelectedPlaceNotifier();
});

/// Computes the selected marker based on the selected place and updates Google markers efficiently
final selectedMarkerProvider = Provider<MapMarker?>((ref) {
  final place = ref.watch(selectedPlaceProvider);
  if (place == null) {
    debugPrint('[selectedMarkerProvider] No place selected');
    return null;
  }

  final markersAsync = ref.watch(markersStateProvider);
  return markersAsync.when(
    data: (markers) {
      debugPrint('[selectedMarkerProvider] Looking for marker with detailsId=${place.placeId}');
      debugPrint('[selectedMarkerProvider] Available markers: ${markers.map((m) => m.detailsId).toList()}');
      final found = markers.firstWhere(
        (m) => m.detailsId == place.placeId,
        orElse: () {
          debugPrint('[selectedMarkerProvider] No marker found for placeId=${place.placeId}, returning placeholder');
          return MapMarker(
            markerId: null,
            detailsId: place.placeId,
            mapId: ref.read(activeMapProvider)?.id ?? '',
            groupId: null,
            information: place,
          );
        },
      );
      debugPrint('[selectedMarkerProvider] Returning marker: $found');
      return found;
    },
    loading: () {
      debugPrint('[selectedMarkerProvider] Markers loading');
      return null;
    },
    error: (err, stack) {
      debugPrint('[selectedMarkerProvider] Markers error: $err');
      return null;
    },
  );
});

// =============================================================================
// Google Maps Markers Management
// =============================================================================

class GoogleMapMarkersNotifier extends StateNotifier<AsyncValue<Set<Marker>>> {
  final GoogleMapsPinsService _pinsService;
  final Ref ref;
  
  GoogleMapMarkersNotifier(this._pinsService, this.ref) : super(const AsyncValue.data({}));

  /// Initializes markers from state
  Future<void> initialize(List<MapMarker> markers, MapMarker? selectedMarker, List<Group> groups) async {
    try {
      if (groups.isEmpty) {
        return;
      }
      state = const AsyncValue.loading();
      final googleMarkers = await _pinsService.initializeMarkers(markers, selectedMarker, groups, ref);
      state = AsyncValue.data(googleMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Updates the selected marker and refreshes the map
  Future<void> updateSelectedMarker(List<MapMarker> stateMarkers, MapMarker? selectedMarker, List<Group> groups) async {
    try {
      state = const AsyncValue.loading();
      final updatedMarkers = await _pinsService.updateSelectedMarker(stateMarkers, selectedMarker, groups, ref);
      state = AsyncValue.data(updatedMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Adds a single marker to the map
  Future<void> addMarker(MapMarker marker, List<Group> groups) async {
    try {
      state = const AsyncValue.loading();
      final googleMarker = await _pinsService.createGoogleMarker(marker, groups, ref: ref, isSelected: false);
      state.whenData((markers) {
        markers.add(googleMarker);
        state = AsyncValue.data(markers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Updates a single marker on the map
  Future<void> updateMarker(MapMarker marker, List<Group> groups) async {
    try {
      state = const AsyncValue.loading();
      final googleMarker = await _pinsService.createGoogleMarker(marker, groups, ref: ref, isSelected: false);
      state.whenData((markers) {
        markers.removeWhere((m) => m.markerId.value == marker.markerId);
        markers.add(googleMarker);
        state = AsyncValue.data(markers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Removes a single marker from the map
  Future<void> removeMarker(String markerId) async {
    try {
      state.whenData((markers) {
        markers.removeWhere((m) => m.markerId.value == markerId);
        state = AsyncValue.data(markers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresca todos los pins usando el estado actual de markersStateProvider
  Future<void> refresh() async {
    try {
      final markers = ref.read(markersStateProvider).maybeWhen(
        data: (m) => m,
        orElse: () => <MapMarker>[],
      );
      final Set<Marker> googleMarkers = {
        for (final marker in markers)
          if (marker.googleMarker != null) marker.googleMarker!
      };
      state = AsyncValue.data(googleMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Filtra los pins mostrando solo los de los grupos activos (group.active == true)
  Future<void> groupFilter() async {
    try {
      final groups = ref.read(groupsStateProvider).maybeWhen(
        data: (g) => g,
        orElse: () => <Group>[],
      );
      final activeGroupIds = groups.where((g) => g.active).map((g) => g.id).whereType<String>().toList();
      print('Active group ids: $activeGroupIds');
      final markers = ref.read(markersStateProvider).maybeWhen(
        data: (m) => m,
        orElse: () => <MapMarker>[],
      );
      final Set<Marker> googleMarkers = {
        for (final marker in markers)
          if (marker.groupId != null && activeGroupIds.contains(marker.groupId) && marker.googleMarker != null)
            marker.googleMarker!
      };
      state = AsyncValue.data(googleMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Filtra los pins por una lista de placeIds (detailsId)
  Future<void> placesFilter(List<String> markerIds) async {
    try {
      final markers = ref.read(markersStateProvider).maybeWhen(
        data: (m) => m,
        orElse: () => <MapMarker>[],
      );
      final Set<Marker> googleMarkers = {
        for (final marker in markers)
          if (markerIds.contains(marker.markerId) && marker.googleMarker != null)
            marker.googleMarker!
      };
      state = AsyncValue.data(googleMarkers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final googleMapMarkersProvider = StateNotifierProvider<GoogleMapMarkersNotifier, AsyncValue<Set<Marker>>>((ref) {
  final pinsService = ref.watch(googleMapsPinsServiceProvider);
  return GoogleMapMarkersNotifier(pinsService, ref);
});

// Listener global para limpiar el estado cuando cambia el mapa activo
final activeMapResetProvider = Provider<void>((ref) {
  ref.listen<MapInfo?>(activeMapProvider, (prev, next) {
    if (prev?.id != next?.id) {
      ref.read(googleMapMarkersProvider.notifier).state = const AsyncValue.data({});
      ref.read(markersStateProvider.notifier).state = const AsyncValue.data([]);
      ref.read(groupsStateProvider.notifier).state = const AsyncValue.data([]);
    }
  });
}); 