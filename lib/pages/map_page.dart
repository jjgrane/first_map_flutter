import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/zoom_button.dart';
import 'package:first_maps_project/widgets/map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  void _handleMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _handleLocationChanged(LatLng location) {
    setState(() {
      _currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            MapView(
              onMapCreated: _handleMapCreated,
              onLocationChanged: _handleLocationChanged,
            ),
            if (_mapController != null && _currentLocation != null)
              Positioned(
                bottom: 90,
                right: 10,
                child: Column(
                  children: [
                    ZoomButton(
                      mapController: _mapController!,
                      zoomDelta: 1,
                      icon: Icons.zoom_in,
                      heroTag: 'zoomIn',
                    ),
                    const SizedBox(height: 10),
                    ZoomButton(
                      mapController: _mapController!,
                      zoomDelta: -1,
                      icon: Icons.zoom_out,
                      heroTag: 'zoomOut',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
