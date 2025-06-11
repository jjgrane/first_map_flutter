import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:first_maps_project/providers/services/services_providers.dart';
import 'package:first_maps_project/providers/maps/markers/marker_providers.dart';
import 'package:first_maps_project/providers/maps/markers/google_marker_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';
part 'group_providers.g.dart'; 

// =============================================================================
// Groups State Management
// =============================================================================


@riverpod
class Groups extends _$Groups {
  /// Se vuelve a ejecutar cada vez que `activeMapProvider` cambia.
  @override
  Future<List<Group>> build() async {
    // Espera a que el mapa activo esté disponible
    final mapInfo = await ref.watch(activeMapProvider.future);

    // Sin mapa activo → lista vacía
    if (mapInfo?.id == null) return const [];

    // Cargar grupos del servicio
    final groupsService = ref.read(firebaseGroupsServiceProvider);
    return await groupsService.getGroupsByMapId(mapInfo!.id!);
  }

  /* ── métodos mutadores (add/remove/update/toggle) irán aquí ── */
  /// ─────────────────────────────  Add  ─────────────────────────────
  Future<Group> addGroup(Group group) async {
    final groupsService = ref.read(firebaseGroupsServiceProvider);

    try {
      // 1. Persistir en el backend → obtengo el ID definitivo
      final groupId = await groupsService.addGroup(group);
      final storedGroup = group.copyWith(id: groupId);

      // 2. Actualizar caché si el estado ya estaba en AsyncData
      state = state.whenData((current) => [...current, storedGroup]);

      return storedGroup;
    } catch (error, stackTrace) {
      // 3. Notificar fallo y propagarlo
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// ─────────────────────────────  Remove  ─────────────────────────────

  Future<void> removeGroup(String groupId) async {
    final groupsService = ref.read(firebaseGroupsServiceProvider);

    try {
      await groupsService.removeGroup(groupId);
      state = state.whenData(
        (groups) => groups.where((g) => g.id != groupId).toList(),
      );      
    } catch (error, stackTrace) {
      // 3. Notificar fallo y propagarlo
      state = AsyncValue.error(error, stackTrace);
    }

  }

  /// ─────────────────────────────  Update  ─────────────────────────────
  Future<void> updateGroup(Group group) async {
    final groupsService = ref.read(firebaseGroupsServiceProvider);

    try {
      /* 1. Snapshot previo para saber si cambió el emoji */
      final previous = state.valueOrNull?.firstWhereOrNull(
        (g) => g.id == group.id,
      );

      /* 2. Persistir en Firestore */
      await groupsService.updateGroup(group);

      /* 3. Actualizar la caché local */
      state = state.whenData(
        (list) => list.map((g) => g.id == group.id ? group : g).toList(),
      );

      /* 4. Si el emoji cambió → delegar la actualización de pins */
      if (previous != null && previous.emoji != group.emoji) {
        ref.read(markersProvider.notifier).groupEmojiUpdate(group);
        // (Implementaremos `groupEmojiUpdate` en el notifier de markers)
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
