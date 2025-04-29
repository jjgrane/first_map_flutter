import 'package:flutter/material.dart';
import 'package:first_maps_project/services/firebase_maps_service.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';

class MapSelectionPage extends StatefulWidget {
  final String mapId;
  final String mapName;

  const MapSelectionPage({
    Key? key,
    required this.mapId,
    required this.mapName,
  }) : super(key: key);

  @override
  MapSelectionPageState createState() => MapSelectionPageState();
}

class MapSelectionPageState extends State<MapSelectionPage> {
  final FirebaseMapsService _mapsService = FirebaseMapsService();
  late Future<List<MapInfo>> _mapsFuture;

  @override
  void initState() {
    super.initState();
    _reloadMaps();
  }

  void _reloadMaps() {
    setState(() {
      _mapsFuture = _mapsService.getAllMaps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: FutureBuilder<List<MapInfo>>(
        future: _mapsFuture,
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
          return ListView.separated(
            itemCount: maps.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Map'),
                  onTap: _createNewMap,
                );
              }
              final map = maps[index - 1];
              final selected = map.id == widget.mapId;
              return ListTile(
                title: Text(map.name),
                subtitle: Text('ID: ${map.id}'),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, map),
              );
            },
          );
        },
      ),
    );
  }

    Future<void> _createNewMap() async {
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
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _mapsService.addMap(MapInfo(name: result));
      _reloadMaps();
    }
  }
}
