import 'package:first_maps_project/providers/maps/markers/google_marker_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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


class _MarkerSetConsumer extends ConsumerStatefulWidget {
  final void Function(Set<Marker>) onMarkersUpdated;
  const _MarkerSetConsumer({required this.onMarkersUpdated});

  @override
  ConsumerState<_MarkerSetConsumer> createState() => _MarkerSetConsumerState();
}

class _MarkerSetConsumerState extends ConsumerState<_MarkerSetConsumer> {
  @override
  Widget build(BuildContext context) {
    // Único listener: cada vez que `googleMapMarkersProvider`
    // emite un AsyncData se pasa el set de pins al MapView.
    ref.listen<AsyncValue<Set<Marker>>>(
      googleMapMarkersProvider,
      (prev, next) => next.whenData(widget.onMarkersUpdated),
    );

    // No necesita mostrar nada.
    return const SizedBox.shrink();
  }
}

