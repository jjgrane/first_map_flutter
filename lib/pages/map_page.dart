import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:first_maps_project/widgets/zoom_button.dart'; 


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();

  static const LatLng _pGooglePlex = LatLng(-34.5928772, -58.3780337);
  static const LatLng _clorindo = LatLng(-34.5933644, -58.3858018);
  LatLng? _currentLocation = null;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(
              child: Text("Loading..."),
            )
          :
      GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,

        initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 13),
        markers: {
          Marker(
            markerId: MarkerId("_GooglePlex"),
            icon: BitmapDescriptor.defaultMarker,
            position: _pGooglePlex!,
          ),
          Marker(
            markerId: MarkerId("_Clorindo"),
            icon: BitmapDescriptor.defaultMarker,
            position: _clorindo,
          ),
        },
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      } else {
        return;
      }
    }
    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((
      LocationData currentLocation,
    ) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentLocation = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
          print(currentLocation);
        });
      }
    });
  }
}
