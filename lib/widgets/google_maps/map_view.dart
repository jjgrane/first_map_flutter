import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/place_information.dart';

class MapView extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onLocationChanged;
  final Marker? searchMarker;

  const MapView({
    super.key,
    required this.onMapCreated,
    required this.onLocationChanged,
    this.searchMarker,
  });

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  final Location _locationController = Location();

  // Valor por defecto (puede ser tu centro de referencia)
  static const LatLng _defaultCenter = LatLng(-34.5928772, -58.3780337);

  @override
  void initState() {
    super.initState();
    _loadMarkersFromFirestore();
    _getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    // defino el punto de inicio de la camara
    LatLng cameraTarget;
    if (_currentLocation != null) {
      cameraTarget = _currentLocation!;
    } else if (_markers.isNotEmpty) {
      cameraTarget = _markers.first.position;
    } else {
      cameraTarget = _defaultCenter;
    }

    final allMarkers = {
      ..._markers,
      if (widget.searchMarker != null) widget.searchMarker!,
    };

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated(controller); // Send controller to parent
      },
      initialCameraPosition: CameraPosition(target: cameraTarget, zoom: 13),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      markers: allMarkers,
    );
  }

  Future<void> _loadMarkersFromFirestore() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();

    final newMarkers =
        snapshot.docs
            .map((doc) {
              try {
                final place = PlaceInformation.fromFirestore(
                  doc.data(),
                  doc.id,
                );

                if (place.location == null) return null;

                return Marker(
                  markerId: MarkerId(place.placeId),
                  position: place.location!,
                  infoWindow: InfoWindow(title: place.name),
                );
              } catch (e) {
                debugPrint('❌ Error parsing marker ${doc.id}: $e');
                return null;
              }
            })
            .whereType<Marker>()
            .toSet();

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

  Future<void> reloadMarkers() async {
    await _loadMarkersFromFirestore();
  }
}
