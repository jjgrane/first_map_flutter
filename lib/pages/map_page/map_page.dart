import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/zoom/zoom_buttons.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/pages/map_page/place_search_bar.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/pages/place_details_page.dart';
import 'package:first_maps_project/pages/map_page/place_preview.dart';
import 'package:first_maps_project/pages/search_screen/place_search_screen.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Marker? _searchMarker;
  PlaceInformation? _selectedPlace;
  LatLng? _cameraCenter;

  final String _googleApiKey = 'AIzaSyBiZ7jrSQuqi50YPIh7uUBzkmnzhoTulAs';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus(); // 👈 quita el foco del teclado
      },
      child: Scaffold(
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
                displayText: _searchController.text,
                onTap: () async {
                  final cameraCenter = await _getCameraCenter();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PlaceSearchScreen(
                            apiKey: _googleApiKey,
                            cameraCenter: cameraCenter,
                            textController: _searchController,
                            onPlaceSelected: _handlePlaceSelected,
                          ),
                    ),
                  );
                },
              ),
              // ZOOM BUTTONS
              ZoomButtons(
                bottom: 90,
                right: 10,
                mapController: _mapController!,
                zoomDelta: 1,
                split: 10,
              ),
              if (_selectedPlace != null)
                PlacePreview(
                  place: _selectedPlace!,
                  onExpand: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PlaceDetailsPage(place: _selectedPlace!),
                      ),
                    );
                  },
                  onClose: () {
                    setState(() {
                      _selectedPlace = null;
                      _searchController.clear();
                      _searchMarker = null;
                    });
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceSelected(PlaceInformation place) async {
    if (context.mounted) {
      Navigator.pop(context);
    }

    final placesService = PlacesService(_googleApiKey);

    // Si no tenemos coordenadas, las pedimos
    PlaceInformation? updatedPlace = place;
    if (place.location == null) {
      updatedPlace = await placesService.getPlaceDetails(place.placeId);
    }

    if (updatedPlace == null) {
      // Mostrar error si no se pudo obtener la información
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No se pudo obtener la información del lugar."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final LatLng? coords = updatedPlace.location;

    if (coords != null && _mapController != null) {
      final marker = updatedPlace.toMarker();

      if (marker != null) {
        setState(() {
          _searchMarker = marker;
          _selectedPlace = updatedPlace;
          _searchController.text = updatedPlace!.name;
        });

        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
      }
    }
  }

  Future<LatLng> _getCameraCenter() async {
    final bounds = await _mapController!.getVisibleRegion();
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }
}
