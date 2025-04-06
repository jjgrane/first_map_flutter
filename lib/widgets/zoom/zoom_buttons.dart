import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/zoom/zoom_map.dart';

class ZoomButtons extends StatelessWidget {
  final double bottom;
  final double right;
  final GoogleMapController mapController;
  final double zoomDelta;
  final double split;

  const ZoomButtons({
    super.key,
    required this.bottom,
    required this.right,
    required this.mapController,
    required this.zoomDelta,
    required this.split,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      right: 10,
      child: Column(
        children: [
          ZoomMap(
            mapController: mapController!,
            zoomDelta: zoomDelta,
            icon: Icons.zoom_in,
            heroTag: 'zoomIn',
          ),
          SizedBox(height: split),
          ZoomMap(
            mapController: mapController!,
            zoomDelta: -zoomDelta,
            icon: Icons.zoom_out,
            heroTag: 'zoomOut',
          ),
        ],
      ),
    );
  }
}
