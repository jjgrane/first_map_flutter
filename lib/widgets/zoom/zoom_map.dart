import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZoomMap extends StatelessWidget {
  final GoogleMapController mapController;
  final double zoomDelta;
  final IconData icon;
  final String heroTag;

  const ZoomMap({
    super.key,
    required this.mapController,
    required this.zoomDelta,
    required this.icon,
    required this.heroTag,
  });

  Future<void> _handleZoom() async {
    // Get current zoom level
    final currentZoom = await mapController.getZoomLevel();

    // Get visible region to calculate map center
    final bounds = await mapController.getVisibleRegion();
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    // Animate camera with updated zoom
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          zoom: currentZoom + zoomDelta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      onPressed: _handleZoom,
      backgroundColor: Colors.white,
      elevation: 1, // leve sombra como Google Maps
      child: Icon(
        icon,
        color: Colors.grey[800], // tono oscuro, pero no negro total
      ),
    );
  }
}
