import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';

class MapView extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final void Function(PlaceInformation) onPlaceSelected;

  const MapView({
    super.key,
    required this.onMapCreated,
    required this.onPlaceSelected,
  });

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  Key _googleMapKey = UniqueKey();
  LatLng? _currentLocation;
  final Location _locationController = Location();
  String? _mapStyle;
  GoogleMapController? _mapController;
  Set<Marker> _currentMarkers = {};

  // Default center value
  static const LatLng _defaultCenter = LatLng(-34.5928772, -58.3780337);

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _googleMapKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _getLocationUpdates();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          key: _googleMapKey,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
            if (_mapStyle != null) {
              controller.setMapStyle(_mapStyle);
            }
          },
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? _defaultCenter,
            zoom: 13,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _currentMarkers,
          style: _mapStyle,
        ),
        _MarkerSetConsumer(
          onMarkersUpdated: (markers) {
            if (!mounted) return;
            setState(() => _currentMarkers = markers);
          },
        ),
      ],
    );
  }

  void _getLocationUpdates() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted =
        await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        if (!mounted) return;
        setState(() {
          _currentLocation = newLocation;
        });
      }
    });
  }

  LatLng? get currentLocation => _currentLocation;
}

// Provider combinado para inicializar pins solo cuando cambia el mapa y todo está listo
final mapReadyProvider =
    Provider<({List<MapMarker> markers, List<Group> groups, MapInfo map})?>((
      ref,
    ) {
      final activeMap = ref.watch(activeMapProvider);
      final markersAsync = ref.watch(markersStateProvider);
      final groupsAsync = ref.watch(groupsStateProvider);

      if (activeMap != null &&
          markersAsync is AsyncData<List<MapMarker>> &&
          groupsAsync is AsyncData<List<Group>>) {
        // Asegura que los valores no sean null
        final markers = markersAsync.value ?? <MapMarker>[];
        final groups = groupsAsync.value ?? <Group>[];
        return (markers: markers, groups: groups, map: activeMap);
      }
      return null;
    });

/// Widget that manages markers using Riverpod
class _MarkerSetConsumer extends ConsumerStatefulWidget {
  final void Function(Set<Marker>) onMarkersUpdated;

  const _MarkerSetConsumer({required this.onMarkersUpdated});

  @override
  ConsumerState<_MarkerSetConsumer> createState() => _MarkerSetConsumerState();
}

class _MarkerSetConsumerState extends ConsumerState<_MarkerSetConsumer> {
  bool _markersInitialized = false;
  String? _lastMapId;

  @override
  Widget build(BuildContext context) {
    ref.watch(activeMapResetProvider);
    ref.listen(googleMapMarkersProvider, (previous, next) {
      next.whenData((markers) {
        widget.onMarkersUpdated(markers);
      });
    });
    ref.listen(mapReadyProvider, (prev, next) {
      if (next != null && !_markersInitialized) {
        print('BBBBBBB-ERRORRRRR - Loading markers for map ');
        ref
            .read(googleMapMarkersProvider.notifier)
            .initialize(
              next.markers,
              ref.read(selectedMarkerProvider),
              next.groups,
            );
        _markersInitialized = true;
      }
    });
    // Listen for changes in the selected marker and update Google markers
    ref.listen(selectedMarkerProvider, (prev, next) {
      final markersAsync = ref.read(markersStateProvider);
      final groupsAsync = ref.read(groupsStateProvider);
      if (markersAsync is AsyncData && groupsAsync is AsyncData) {
        ref
            .read(googleMapMarkersProvider.notifier)
            .updateSelectedMarker(
              markersAsync.value ?? [],
              next,
              groupsAsync.value ?? [],
            );
      }
    });

    // Flag logic: only load markers once per map id
    final groupsAsync = ref.watch(groupsStateProvider);
    final mapId = ref.watch(activeMapProvider)?.id;
    if (mapId != _lastMapId) {
      _markersInitialized = false;
      _lastMapId = mapId;
    }
    if (!_markersInitialized && groupsAsync is AsyncData<List<Group>>) {
      if (mapId != null) {
        print('AAAAAA-ERRORRRRR - Loading markers for map id: $mapId');
        ref.read(markersStateProvider.notifier).loadMarkers();
      }
    }

    return const SizedBox.shrink();
  }
}
