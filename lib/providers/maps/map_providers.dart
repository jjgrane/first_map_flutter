import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/providers/services/services_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'map_providers.g.dart'; 


// =============================================================================
// Active Map Provider
// =============================================================================

@riverpod
class ActiveMap extends _$ActiveMap {
  /// Se ejecuta una sola vez (o tras `ref.refresh`/`ref.invalidate`).
  @override
  Future<MapInfo?> build() async {
    final mapsService = ref.read(firebaseMapsServiceProvider);   // inyección
    final maps = await mapsService.getAllMaps();

    final def = maps.firstWhere(
      (m) => m.name == 'default',
      orElse: () => MapInfo(id: '', name: '', owner: ''),
    );

    return def.id?.isEmpty ?? true ? null : def;
  }

  /* ---------------- Métodos mutadores ---------------- */

  /// Selecciona manualmente otro mapa (se propaga como AsyncData)
  void select(MapInfo map) => state = AsyncData(map);

  /// Limpia la selección
  void clear() => state = const AsyncData(null);
}