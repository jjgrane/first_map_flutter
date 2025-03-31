import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapView extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onLocationChanged;

  const MapView({
    super.key,
    required this.onMapCreated,
    required this.onLocationChanged,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Location _locationController = Location();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};

  final LatLng _marker1 = const LatLng(-34.5928772, -58.3780337);
  final LatLng _marker2 = const LatLng(-34.5933644, -58.3858018);

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return _currentLocation == null
        ? const Center(child: CircularProgressIndicator())
    : GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated(controller); // Send controller to parent
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation!,
        zoom: 13,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      markers: _markers,
    );
  }

  void _initializeMarkers() {
    _markers.addAll([
      Marker(
        markerId: MarkerId("m1"),
        position: _marker1,
        infoWindow: InfoWindow(title: "GooglePlex?"),
      ),
      Marker(
        markerId: MarkerId("m2"),
        position: _marker2,
        infoWindow: InfoWindow(title: "Clorindo"),
      ),
    ]);
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
        setState(() {
          _currentLocation = newLocation;
        });
        widget.onLocationChanged(newLocation); // Send location to parent
      }
    });
  }
}
