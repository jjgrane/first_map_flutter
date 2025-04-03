import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/zoom/zoom_buttons.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/widgets/google_maps/search_bar/place_search_bar.dart';
import 'package:first_maps_project/services/places_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Marker? _searchMarker;
  final String _googleApiKey = 'AIzaSyBiZ7jrSQuqi50YPIh7uUBzkmnzhoTulAs';
  // Dentro del widget:
  final TextEditingController _searchController = TextEditingController();

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
      body: Stack(
        children: [
          MapView(
            onMapCreated: _handleMapCreated,
            onLocationChanged: _handleLocationChanged,
            searchMarker: _searchMarker,
          ),
          //Add map gadgets
          if (_mapController != null) ...[
            // SEARCH BAR
            PlaceSearchBar(
              textController: _searchController,
              apiKey: _googleApiKey,
              onPlaceSelected: _handlePlaceSelected,
            ),
            // ZOOM BUTTONS
            Positioned(
              bottom: 90,
              right: 10,
              child: ZoomButtons(
                mapController: _mapController!,
                zoomDelta: 1,
                split: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handlePlaceSelected(String place) async {
    final placesService = PlacesService(_googleApiKey);
    final LatLng? coords = await placesService.getCoordinatesFromPlace(place);

    if (coords != null && _mapController != null) {
      // Agrega marcador momentáneo
      final marker = Marker(
        markerId: const MarkerId('search_marker'),
        position: coords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: place),
      );

      setState(() {
        _searchMarker = marker;
      });

      // Centra la cámara en la ubicación
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
    }
  }
}
