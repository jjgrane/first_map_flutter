import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/pages/place_details_page.dart';

class MapPlacesListView extends StatefulWidget {
  const MapPlacesListView({super.key});

  @override
  State<MapPlacesListView> createState() => _MapPlacesListViewState();
}

class _MapPlacesListViewState extends State<MapPlacesListView> {
  final Set<String> _expandedGroupIds = {};
  List<Group> _groups = [];
  List<MapMarker> _markers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final groupsAsync = container.read(groupsStateProvider);
    final markersAsync = container.read(markersStateProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    // Handle groups
    groupsAsync.when(
      data: (groups) => _groups = groups,
      loading: () => _loading = true,
      error: (err, _) {
        _error = err.toString();
        _groups = [];
      },
    );
    // Handle markers
    markersAsync.when(
      data: (markers) => _markers = markers,
      loading: () => _loading = true,
      error: (err, _) {
        _error = err.toString();
        _markers = [];
      },
    );
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('All Places')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Places')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    if (_groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Places')),
        body: const Center(child: Text('No groups available.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('All Places')),
      body: ListView(
        children: _groups.map((group) {
          final groupPlaces = _markers.where((m) => m.groupId == group.id).toList();
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
                                builder: (_) => const PlaceDetailsPage(),
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