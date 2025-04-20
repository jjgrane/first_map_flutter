import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/zoom/zoom_buttons.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/pages/map_page/place_search_bar.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/pages/place_details_page.dart';
import 'package:first_maps_project/pages/map_page/place_preview.dart';
import 'package:first_maps_project/pages/search_page/search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Marker? _searchMarker;
  PlaceInformation? _selectedPlace;
  String _currentMap = "My Personal Map";
  String? _selectedPlaceName;

  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<MapViewState> _mapKey = GlobalKey<MapViewState>();
  late final PlacesService _placesService;

  @override
  void initState() {
    _placesService = PlacesService(_googleApiKey);
  }

  void _handleMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            MapView(
              key: _mapKey,
              onMapCreated: _handleMapCreated,
              searchMarker: _searchMarker,
              onPlaceSelected: _handlePlaceTap,
            ),
            //Add map gadgets
            if (_mapController != null) ...[
              // SEARCH BAR
              PlaceSearchBar(
                displayText: _selectedPlaceName ?? _currentMap,
                onTap: () async {
                  final cameraCenter = await _getCameraCenter();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SearchPage(
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
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PlaceDetailsPage(
                                place: _selectedPlace!,
                                mapViewKey: _mapKey,
                              ),
                        ),
                      );
                    },
                    child: PlacePreview(
                      place: _selectedPlace!,
                      onClose: () {
                        setState(() {
                          _selectedPlaceName = null;
                          _selectedPlace = null;
                          _searchController.clear();
                          _searchMarker = null;
                        });
                      },
                      placeService: _placesService,
                    ),
                  ),
                ),
            ],
          ],
        ),
    );
  }

  Future<void> _handlePlaceSelected(
    PlaceInformation place,
    String? sessionToken,
  ) async {
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Si no tenemos coordenadas, las pedimos -- OPTIMIZABLE, ESTO DEBERIA SALIR DE BASE DE DATOS.
    PlaceInformation? updatedPlace = place;
    if (place.location == null) {
      updatedPlace = await _placesService.getPlaceDetails(
        place.placeId,
        sessionToken,
      );
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
          _selectedPlaceName = updatedPlace!.name;
          _searchController.text = _selectedPlaceName!;
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

  void _handlePlaceTap(PlaceInformation place) {
    print("ITEM TAPPED");
    setState(() {
      _selectedPlace = place;
      _selectedPlaceName = place.name;
    });
  }
}
