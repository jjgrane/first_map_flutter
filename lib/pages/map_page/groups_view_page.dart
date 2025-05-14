import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/providers/map_providers.dart';

/// Displays all group icons (pinIcon) for the active map and allows adding the given place to a group.
/// Returns [MapMarker] when a group is selected or created, or null on cancel.
class GroupsViewPage extends ConsumerWidget {
  final MapMarker? currentMarker;

  const GroupsViewPage({
    super.key,
    this.currentMarker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado de los marcadores, pero solo extraemos los íconos únicos
    final uniqueIcons = ref.watch(
      markersStateProvider.select((state) => 
        state.whenData((markers) => 
          markers
            .map((marker) => marker.pinIcon)
            .where((icon) => icon.isNotEmpty)
            .toSet()
        )
      )
    );
    
    // Solo observamos si el mapa y lugar existen, no sus valores completos
    final hasRequiredData = ref.watch(
      Provider.autoDispose((ref) {
        final hasMap = ref.watch(activeMapProvider.select((map) => map != null));
        final hasPlace = ref.watch(selectedPlaceProvider.select((place) => place != null));
        return hasMap && hasPlace;
      })
    );

    if (!hasRequiredData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign to Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uniqueIcons.when(
        data: (icons) {
          final iconsList = icons.toList();
          return ListView.separated(
            itemCount: iconsList.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create & Add New Group'),
                  onTap: () => _createAndAddGroup(context, ref),
                );
              }
              final icon = iconsList[index - 1];
              final isCurrent = currentMarker?.pinIcon == icon;
              return ListTile(
                leading: _buildLeading(icon),
                title: Text(icon),
                selected: isCurrent,
                selectedTileColor: Colors.lightBlueAccent.withOpacity(0.3),
                enabled: !isCurrent,
                onTap: isCurrent ? null : () => _addToGroup(context, ref, icon),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLeading(String icon) {
    if (icon.startsWith('assets/') || icon.endsWith('.png')) {
      return Image.asset(
        icon,
        width: 24,
        height: 24,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      return Text(icon, style: const TextStyle(fontSize: 24));
    }
  }

  Future<void> _addToGroup(BuildContext context, WidgetRef ref, String icon) async {
    final activeMap = ref.read(activeMapProvider);
    final selectedPlace = ref.read(selectedPlaceProvider);

    if (activeMap == null || selectedPlace == null) {
      Navigator.pop(context);
      return;
    }

    if (currentMarker != null && currentMarker!.markerId != null) {
      // Update existing marker
      final updated = currentMarker!.copyWith(pinIcon: icon);
      await ref.read(markersStateProvider.notifier).updateMarker(updated);
      if (!context.mounted) return;
      Navigator.pop(context, updated);
    } else {
      // Create a new marker
      final marker = MapMarker(
        markerId: null,
        detailsId: selectedPlace.placeId,
        mapId: activeMap.id!,
        pinIcon: icon,
        information: selectedPlace,
      );
      await ref.read(markersStateProvider.notifier).addMarker(marker);
      if (!context.mounted) return;
      Navigator.pop(context, marker);
    }
  }

  Future<void> _createAndAddGroup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    try {
      final icon = await showDialog<String?>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('New Group Icon'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Emoji or asset path',
              hintText: 'e.g. 🍕 or assets/icons/pin.png',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = controller.text.trim();
                Navigator.pop(context, input.isEmpty ? null : input);
              },
              child: const Text('Create & Add'),
            ),
          ],
        ),
      );

      if (icon != null) {
        await _addToGroup(context, ref, icon);
      }
    } finally {
      controller.dispose();
    }
  }
}
