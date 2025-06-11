import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/providers/services/services_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:first_maps_project/providers/maps/markers/marker_providers.dart';
import 'package:first_maps_project/providers/maps/group/group_providers.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:collection/collection.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/group.dart';
part 'google_marker_provider.g.dart';

// =============================================================================
// Google Maps Markers Management
// =============================================================================
@riverpod
class GoogleMapMarkers extends _$GoogleMapMarkers {
  @override
  Future<Set<Marker>> build() async {
    /* 1. Recalcular solo al cambiar de mapa */
    final mapInfo = await ref.watch(activeMapProvider.future);
    if (mapInfo == null) return {};

    /* 2. Lista actual de MapMarker (ya con googleMarker y visible) */
    final markers = await ref.read(markersProvider.future);

    /* 4. Construir Set<Marker> filtrado y con z-index correcto */
    final Set<Marker> googleMarkers = {
      for (final m in markers)
        if (m.visible && m.googleMarker != null) m.googleMarker!,
    };

    return googleMarkers;
  }

  /* ─────────────────────────  Add  ───────────────────────── */
  void addMarker(Marker googleMarker) {
    state = state.whenData((pins) => {...pins, googleMarker});
  }

  /* ─────────────────────────  Update  ─────────────────────── */
  void updateMarker(Marker googleMarker) {
    final String id = googleMarker.markerId.value;

    state = state.whenData((pins) {
      final updated = {
        for (final m in pins)
          if (m.markerId.value != id) m, // conserva todos salvo el viejo
      }..add(googleMarker); // añade la versión nueva
      return updated;
    });
  }

  /* ─────────────────────────  Remove  ─────────────────────── */
  void removeMarker(String markerId) {
    state = state.whenData(
      (pins) => pins.where((m) => m.markerId != markerId).toSet(),
    );
  }

  /* ─────────────────────────────  Refresh  ───────────────────────────── */
  Future<void> refresh() async {
    try {
      state = const AsyncLoading();

      /* 1. Asegurar que hay mapa activo */
      final mapInfo = ref.read(activeMapProvider).value;
      if (mapInfo == null) {
        state = const AsyncData({});
        return;
      }

      /* 2. Obtener marcadores enriquecidos */
      final markers = await ref.read(markersProvider.future);

      /* 3. Identificar el marcador seleccionado */
      final selectedPlaceId = ref.read(selectedPlaceProvider)?.placeId;
      final pinsService = ref.read(googleMapsPinsServiceProvider);

      /* 4. Construir set de GoogleMarkers */
      final Set<Marker> googleMarkers = {
        for (final m in markers)
          if (m.visible && m.googleMarker != null)
            // ¿es el marcador seleccionado?
            if (m.detailsId == selectedPlaceId)
              // Sólo en este caso necesitamos el grupo
              await () async {
                final groups = await ref.read(groupsProvider.future);
                final group = groups.firstWhereOrNull((g) => g.id == m.groupId);

                return pinsService.createGoogleMarker(
                  marker: m,
                  group: group,
                  isSelected: true,
                  onTap:
                      () => ref
                          .read(selectedPlaceProvider.notifier)
                          .update(m.information!),
                );
              }()
            else
              // Reutilizar el googleMarker cacheado para el resto
              m.googleMarker!.copyWith(zIndexParam: 1),
      };

      state = AsyncData(googleMarkers);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> applySelection({
    PlaceInformation? previous,
    PlaceInformation? next,
  }) async {
    // 0. Si aún no hay pins cargados, salir.
    if (state.valueOrNull == null) return;

    /* B. dominio de markers + servicio de pins */
    final markersDomain = ref.read(markersProvider).valueOrNull ?? [];
    final pinsService   = ref.read(googleMapsPinsServiceProvider);

    /* ───── 1. Procesar marcador anterior (des-seleccionar) ───── */
    if (previous != null) {
      final prevId      = previous.placeId;
      final prevDomain  =
          markersDomain.firstWhereOrNull((m) => m.detailsId == prevId);

      if (prevDomain == null) {
        // No existe en dominio → quitarlo del set visual
        removeMarker(prevId);
      } else if (prevDomain.googleMarker != null) {
        // Existe → bajar su zIndex
        final gm = prevDomain.googleMarker!;
        updateMarker(gm);                               
      }
    }

    /* ───────── 2. Seleccionar el nuevo pin ───────── */
    if (next != null) {
      final nextId = next.placeId;

      final nextDomain = markersDomain.firstWhereOrNull(
        (m) => m.detailsId == nextId,
      );

      if (nextDomain != null) {
        // Buscar grupo (solo para este pin)
        final groups = ref.read(groupsProvider).valueOrNull ?? <Group>[];
        final group  =
            groups.firstWhereOrNull((g) => g.id == nextDomain.groupId);

        // Re-crear icono con estilo “selected”
        final gmSelected = await pinsService.createGoogleMarker(
          marker:     nextDomain,
          group:      group,
          isSelected: true,
          onTap: () => ref
              .read(selectedPlaceProvider.notifier)
              .update(nextDomain.information!),
        );

        updateMarker(gmSelected);      // sustituye/añade en el set visual
      }
    }
  }
}
