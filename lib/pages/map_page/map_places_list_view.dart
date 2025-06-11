import 'package:first_maps_project/providers/maps/group/group_providers.dart';
import 'package:first_maps_project/providers/maps/markers/marker_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/pages/place_details_page.dart';

class MapPlacesListView extends ConsumerStatefulWidget {
  const MapPlacesListView({super.key});

  @override
  ConsumerState<MapPlacesListView> createState() =>
      _MapPlacesListViewState();
}

class _MapPlacesListViewState extends ConsumerState<MapPlacesListView> {
  final Set<String> _expandedGroupIds = {};

  @override
  Widget build(BuildContext context) {
    // Datos reactivos
    final groupsAsync  = ref.watch(groupsProvider);
    final markersAsync = ref.watch(markersProvider);

    // Combinar estados: mostrar spinner si cualquiera carga
    if (groupsAsync.isLoading || markersAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Manejo de errores
    if (groupsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Places')),
        body: Center(child: Text('Error: $groupsAsync.error')),
      );
    }
    if (markersAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Places')),
        body: Center(child: Text('Error: $markersAsync.error')),
      );
    }

    final groups  = groupsAsync.value!;
    final markers = markersAsync.value!;

    if (groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Places')),
        body: const Center(child: Text('No groups available.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('All Places')),
      body: ListView(
        children: groups.map((group) {
          final groupPlaces = markers.where((m) => m.groupId == group.id).toList();
          final isExpanded = _expandedGroupIds.contains(group.id);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: Text(group.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(group.name),
                  subtitle: Text('${groupPlaces.length} place${groupPlaces.length == 1 ? '' : 's'}'),
                  trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedGroupIds.remove(group.id);
                      } else {
                        _expandedGroupIds.add(group.id!);
                      }
                    });
                  },
                ),
                if (isExpanded)
                  ...groupPlaces.map((marker) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 56, right: 16),
                        title: Text(marker.information?.name ?? 'No name'),
                        subtitle: Text(marker.information?.address ?? ''),
                        onTap: () {
                          // Update selectedPlaceProvider and navigate
                          final container = ProviderScope.containerOf(context, listen: false);
                          final info = marker.information;
                          if (info != null) {
                            container.read(selectedPlaceProvider.notifier).update(info);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceDetailsPage(marker: marker),
                              ),
                            );
                          }
                        },
                      )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
} 