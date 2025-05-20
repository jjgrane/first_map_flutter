import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_maps_service.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';

class MapSelectionPage extends ConsumerWidget {
  const MapSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsService = FirebaseMapsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<MapInfo>>(
        future: mapsService.getAllMaps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading maps: ${snapshot.error}'),
            );
          }
          final maps = snapshot.data!;
          final currentMapId = ref.read(activeMapProvider)?.id;
          
          return ListView.separated(
            itemCount: maps.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Map'),
                  onTap: () => _createNewMap(context, ref, mapsService),
                );
              }
              final map = maps[index - 1];
              final selected = map.id == currentMapId;
              
              return ListTile(
                title: Text(map.name),
                subtitle: Text('ID: ${map.id}'),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  ref.read(activeMapProvider.notifier).setActiveMap(map);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createNewMap(BuildContext context, WidgetRef ref, FirebaseMapsService mapsService) async {
    final nameController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Map'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Map Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newMap = await mapsService.addMap(MapInfo(name: result));
      ref.read(activeMapProvider.notifier).setActiveMap(newMap);
      Navigator.pop(context);
    }
  }
}
