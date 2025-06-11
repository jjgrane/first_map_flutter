import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/pages/map_page/groups_view_page.dart';
import 'package:first_maps_project/providers/maps/markers/marker_providers.dart';
import 'package:first_maps_project/providers/maps/group/group_providers.dart';
import 'package:first_maps_project/widgets/models/group.dart';

class PlaceDetailsPage extends ConsumerWidget {
  const PlaceDetailsPage({super.key, required this.marker});
  final MapMarker marker;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(selectedPlaceProvider);
    
    // Si no hay lugar seleccionado, volvemos atrás
    if (place == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    // Observar el marcador actual
    final currentMarker = marker;
    final isSaved = currentMarker.markerId != null;

    // Buscar el emoji del grupo si el marcador está guardado
    String? savedEmoji;
    if (isSaved && currentMarker?.groupId != null) {
      final groupsAsync = ref.watch(groupsProvider);
      groupsAsync.whenData((groups) {
        Group? group;
        for (final g in groups) {
          if (g.id == currentMarker!.groupId) {
            group = g;
            break;
          }
        }
        savedEmoji = group?.emoji;
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📍 ${place.name}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              place.address ?? "no data",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              place.location != null
                  ? "🗺️ Coordenadas: ${place.location!.latitude}, ${place.location!.longitude}"
                  : "🗺️ Coordenadas: no data",
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push<MapMarker?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupsViewPage(
                            currentMarker: currentMarker,
                          ),
                        ),
                      );
                      
                      if (result != null && context.mounted) {
                        _showSnack(
                          context, 
                          isSaved ? '✅ Grupo actualizado' : '✅ Lugar agregado'
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved ? Colors.orange : Colors.green,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSaved && savedEmoji != null) ...[
                          Text(
                            savedEmoji!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          const Text("Cambiar Grupo"),
                        ] else ...[
                          const Icon(Icons.add_location_alt),
                          const SizedBox(width: 8),
                          const Text("Agregar a Grupo"),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isSaved) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(markersProvider.notifier)
                          .removeMarker(currentMarker.markerId!);
                        if (context.mounted) {
                          _showSnack(context, '🗑️ Lugar eliminado');
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Eliminar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
