import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:first_maps_project/providers/services/services_providers.dart';
import 'package:first_maps_project/providers/maps/group/group_providers.dart';
import 'package:first_maps_project/providers/maps/markers/google_marker_provider.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'marker_providers.g.dart';

// =============================================================================
// Markers State Management
// =============================================================================
@riverpod
class Markers extends _$Markers {
  @override
  Future<List<MapMarker>> build() async {
    /* 1. Reactivar solo cuando cambie el mapa activo */
    final mapInfo = await ref.watch(activeMapProvider.future);
    if (mapInfo?.id == null) return const [];

    /* 2. Descarga de los MapMarker crudos */
    final markersService = ref.read(firebaseMarkersServiceProvider);
    final rawMarkers = await markersService.getMarkersByMapId(mapInfo!.id!);

    /* 3. Grupos – lectura UNA sola vez */
    final groups = await ref.read(
      groupsProvider.future,
    ); // no dependencia reactiva

    /* 4. Servicio de pines y función onTap */
    final pinsService = ref.read(googleMapsPinsServiceProvider);

    /* 5. Enriquecer cada MapMarker con su GoogleMarker */
    final enriched = await Future.wait(
      rawMarkers.map((m) async {
        final group = groups.firstWhereOrNull((g) => g.id == m.groupId);

        final gm = await pinsService.createGoogleMarker(
          marker: m,
          group: group,
          onTap:
              () => ref
                  .read(selectedPlaceProvider.notifier)
                  .update(m.information!),
        );

        return m.copyWith(googleMarker: gm);
      }),
    );

    return enriched;
  }

  /// ─────────────────────────────  Add  ─────────────────────────────
  Future<void> addMarker(MapMarker marker, [Group? groupInput]) async {
    final markersService = ref.read(firebaseMarkersServiceProvider);
    final pinsService = ref.read(googleMapsPinsServiceProvider);

    try {
      /* 1. Persistir en backend */
      final markerId = await markersService.addMarker(marker);
      final storedMarker = marker.copyWith(markerId: markerId);

      /* 2. Obtener grupos (una sola vez, sin dependencia reactiva) */
      final groups = await ref.read(groupsProvider.future);

      /* 3. Localizar el grupo correspondiente (puede ser null) */
      final group =
          groupInput ??
          groups.firstWhereOrNull((g) => g.id == storedMarker.groupId);

      /* 4. Crear GoogleMarker */
      final selectedPlaceId = ref.read(selectedPlaceProvider)?.placeId;
      final googleMarker = await pinsService.createGoogleMarker(
        marker: storedMarker,
        group: group,
        isSelected: storedMarker.detailsId == selectedPlaceId,
        onTap:
            () => ref
                .read(selectedPlaceProvider.notifier)
                .update(storedMarker.information!),
      );

      final enrichedMarker = storedMarker.copyWith(googleMarker: googleMarker);

      /* 5. Actualizar caché local si ya estaba en AsyncData */
      state = state.whenData((list) => [...list, enrichedMarker]);

      /* 6. Notificar al set de GoogleMap pins */
      ref.read(googleMapMarkersProvider.notifier).addMarker(googleMarker);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // quítalo si no necesitas propagar la excepción
    }
  }

  /// ─────────────────────────────  Remove  ─────────────────────────────
  Future<void> removeMarker(String markerId) async {
    final service = ref.read(firebaseMarkersServiceProvider);

    try {
      // 1. Backend
      await service.removeMarker(markerId);

      // 2. Cache local
      state = state.whenData(
        (list) => list.where((m) => m.markerId != markerId).toList(),
      );

      // 3. Refrescar set de GoogleMarkers mostrado en el mapa
      ref.read(googleMapMarkersProvider.notifier).removeMarker(markerId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // quítalo si no capturas la excepción en capas superiores
    }
  }

  /// ─────────────────────────────  Update  ────────────────────────────
  Future<void> updateMarker(MapMarker marker, [Group? groupInput]) async {
    final markersService = ref.read(firebaseMarkersServiceProvider);
    final pinsService = ref.read(googleMapsPinsServiceProvider);

    try {
      /* 1. Persistir cambios en backend */
      await markersService.updateMarker(marker);

      /* 2. Obtener grupos actuales (una sola vez, sin dependencia reactiva) */
      final groups = await ref.read(groupsProvider.future);
      final Group? group =
          groupInput ?? groups.firstWhereOrNull((g) => g.id == marker.groupId);

      /* 3. (Re)generar el GoogleMarker con icono correcto */
      final googleMarker = await pinsService.createGoogleMarker(
        marker: marker,
        group: group,
        onTap:
            () => ref
                .read(selectedPlaceProvider.notifier)
                .update(marker.information!),
      );

      final updated = marker.copyWith(googleMarker: googleMarker);

      /* 4. Actualizar caché local (si estaba en AsyncData) */
      state = state.whenData(
        (list) =>
            list
                .map((m) => m.markerId == marker.markerId ? updated : m)
                .toList(),
      );

      /* 5. Notificar al set consumido por el widget GoogleMap */
      ref.read(googleMapMarkersProvider.notifier).updateMarker(googleMarker);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // quítalo si no necesitas propagar la excepción
    }
  }

  Future<void> groupEmojiUpdate(Group group) async {
    // 1. Si la lista de marcadores aún no está cargada, no hacemos nada.
    final current = state.valueOrNull;
    if (current == null) return;

    // 2. Filtrar los marcadores que pertenecen al grupo cuyo emoji cambió.
    final affected = current.where((m) => m.groupId == group.id).toList();
    if (affected.isEmpty) return;

    // 3. Llamar a updateMarker en paralelo para cada uno.
    await Future.wait(affected.map((m) => updateMarker(m, group)));
  }

  /// ─────────────────────────────  marker for place  ────────────────────────────

  MapMarker markerForPlace(PlaceInformation place) {
    // 1. Buscar en la lista cargada (si aún no está, devolvemos placeholder)
    final existing = state.valueOrNull?.firstWhereOrNull(
      (m) => m.detailsId == place.placeId,
    );

    if (existing != null) return existing;

    // 2. Construir placeholder
    final mapId = ref.read(activeMapProvider).value?.id ?? '';

    return MapMarker(
      markerId: null,
      detailsId: place.placeId,
      mapId: mapId,
      groupId: null,
      information: place,
    );
  }

  /// ──────────────────────  Apply Group Visibility  ────────────────────── ///
  /* ─────────────────── 1. Filtrar por lista de groupId ─────────────────── */
  void applyGroupVisibility(List<String> allowedGroupIds) {
    state = state.whenData((list) {
      final bool showAll = allowedGroupIds.isEmpty;

      final updated = [
        for (final m in list)
          m.copyWith(
            visible:
                showAll
                    ? true
                    : (m.groupId != null &&
                        allowedGroupIds.contains(m.groupId)),
          ),
      ];
      return updated;
    });

    // Refrescar el set de GoogleMarkers para que la UI se actualice
    ref.read(googleMapMarkersProvider.notifier).refresh();
  }

  /* ─────────────────── 2. Filtrar por lista de markerId ─────────────────── */
  void applyMarkerVisibility(List<String> allowedMarkerIds) {
    state = state.whenData((list) {
      final updated = [
        for (final m in list)
          m.copyWith(visible: allowedMarkerIds.contains(m.markerId)),
      ];
      return updated;
    });

    // Refrescar el set de pins mostrado en Google Map
    ref.read(googleMapMarkersProvider.notifier).refresh();
  }
}

// =============================================================================
// Selected Place Management
// =============================================================================
/// ─────────────────── 1. Notifier para el lugar seleccionado ───────────────────
@riverpod
class SelectedPlace extends _$SelectedPlace {
  @override
  PlaceInformation? build() => null;

  void update(PlaceInformation place) {
    final prev = state; // snapshot anterior
    state = place; // nuevo seleccionado

    ref
        .read(googleMapMarkersProvider.notifier)
        .applySelection(previous: prev, next: place);
  }

  void clear() {
    final prev = state; // último seleccionado
    state = null; // sin selección

    ref
        .read(googleMapMarkersProvider.notifier)
        .applySelection(previous: prev, next: null);
  }
}
