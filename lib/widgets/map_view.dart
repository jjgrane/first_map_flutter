import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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


  @override
  void initState() {
    super.initState();
    _loadMarkersFromFirestore();
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

Future<void> _loadMarkersFromFirestore() async {
  final snapshot = await FirebaseFirestore.instance.collection('markers').get();

  final newMarkers = snapshot.docs.map((doc) {
    final data = doc.data();
    return Marker(
      markerId: MarkerId(doc.id),
      position: LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      ),
      infoWindow: InfoWindow(title: data['title'] ?? 'No title'),
    );
  }).toSet();

  setState(() {
    _markers.addAll(newMarkers);
  });
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
