import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/providers/map_providers.dart';

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
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          markers: _currentMarkers,
          style: _mapStyle,
        ),
        _MarkerSetConsumer(
          onPlaceSelected: widget.onPlaceSelected,
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

    PermissionStatus permissionGranted = await _locationController.hasPermission();
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
}

/// Widget that manages markers using Riverpod
class _MarkerSetConsumer extends ConsumerWidget {
  final void Function(PlaceInformation) onPlaceSelected;
  final void Function(Set<Marker>) onMarkersUpdated;

  const _MarkerSetConsumer({
    required this.onPlaceSelected,
    required this.onMarkersUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the active map to trigger updates when it changes
    final activeMap = ref.watch(activeMapProvider);
    
    // Listen to markers state changes
    ref.listen(markersStateProvider, (previous, next) {
      _updateMarkersFromState(ref);
    });

    // Listen to selected marker changes
    ref.listen(selectedMarkerProvider, (previous, next) {
      _updateSelectedMarker(ref);
    });

    return const SizedBox.shrink();
  }

  Future<void> _updateMarkersFromState(WidgetRef ref) async {
    final markersNotifier = ref.read(googleMapMarkersProvider.notifier);
    markersNotifier.setLoading();

    try {
      final markersAsync = ref.read(markersStateProvider);
      final selectedMarker = ref.read(selectedMarkerProvider);
      final converter = ref.read(markerConverterProvider);

      final Set<Marker> markers = await markersAsync.when(
        data: (markers) async {
          return await converter.convertToGoogleMarkers(markers, selectedMarker: selectedMarker);
        },
        loading: () => <Marker>{},
        error: (error, stack) => <Marker>{},
      );

      markersNotifier.updateMarkers(markers);
      onMarkersUpdated(markers);
    } catch (error, stackTrace) {
      markersNotifier.setError(error, stackTrace);
    }
  }

  Future<void> _updateSelectedMarker(WidgetRef ref) async {
    final selectedMarker = ref.read(selectedMarkerProvider);
    final markersAsync = ref.read(markersStateProvider);
    final converter = ref.read(markerConverterProvider);
    final markersNotifier = ref.read(googleMapMarkersProvider.notifier);

    await markersAsync.when(
      data: (markers) async {
        Set<Marker> finalMarkers;
        
        if (selectedMarker == null) {
          // Si no hay marcador seleccionado, convertimos solo los marcadores del state
          finalMarkers = await converter.convertToGoogleMarkers(markers, selectedMarker: null);
        } else if (!markers.any((m) => m.markerId == selectedMarker.markerId)) {
          // Si el marcador no existe en la lista, combinamos
          final baseMarkers = await converter.convertToGoogleMarkers(markers, selectedMarker: null);
          final selectedGoogleMarker = await converter.convertToGoogleMarkers([selectedMarker], selectedMarker: selectedMarker);
          finalMarkers = {...baseMarkers, ...selectedGoogleMarker};
        } else {
          // Si el marcador ya existe en la lista, no hacemos nada
          return;
        }

        markersNotifier.updateMarkers(finalMarkers);
        onMarkersUpdated(finalMarkers);
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }
}
