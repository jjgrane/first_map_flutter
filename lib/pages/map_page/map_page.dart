import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/pages/map_page/place_search_bar.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/pages/place_details_page.dart';
import 'package:first_maps_project/pages/map_page/place_preview.dart';
import 'package:first_maps_project/pages/search_page/search_page.dart';
import 'package:first_maps_project/pages/map_page/map_selection_page.dart';
import 'package:first_maps_project/providers/maps/markers/marker_providers.dart';
import 'package:first_maps_project/pages/map_page/map_places_list_view.dart';
import 'package:first_maps_project/pages/map_page/map_button.dart';
import 'package:first_maps_project/services/maps/map_manager.dart';
import 'package:first_maps_project/widgets/google_maps/filter_group_buttons.dart';

// Main page displaying the Google Map and related overlays
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  // Keys and Controllers
  final GlobalKey<MapViewState> _mapKey = GlobalKey<MapViewState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map Manager
  late final MapManager _mapManager;

  // Map State
  String? _currentMapName;
  String? _selectedPlaceName;

  @override
  void initState() {
    super.initState();
    _mapManager = MapManager();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildMapStack());
  }

  Widget _buildMapStack() {
    return Stack(
      children: [
        _buildMapView(),
        _buildSearchBar(),
        _buildButtonsOverlay(),
        _buildPlacePreviewPositioned(),
      ],
    );
  }

  Widget _buildMapView() {
    return MapView(
      key: _mapKey,
      onMapCreated: _handleMapCreated,
      onPlaceSelected: _handlePlaceTap,
    );
  }

  Widget _buildSearchBar() {
    return PlaceSearchBar(
      displayText: _selectedPlaceName ?? _currentMapName ?? '',
      onTap: () async {
        final cameraCenter = await _getCameraCenter() ?? const LatLng(0, 0);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => SearchPage(
                  apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                  cameraCenter: cameraCenter,
                  textController: _searchController,
                  onPlaceSelected: _handlePlaceSelected,
                ),
          ),
        );
      },
    );
  }

  Widget _buildButtonsOverlay() {
    final bool showPreview = ref.watch(selectedPlaceProvider) != null;
    final double base = 40, offset = showPreview ? 24 + 140 : 0;
    return Positioned(
      bottom: base + offset,
      right: 10,
      child: SizedBox(
        height: 3000.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // map selection button
            MapButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapSelectionPage()),
                );
              },
              icon: Icons.map,
            ),
            const SizedBox(width: 12),
            // list view button
            MapButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPlacesListView()),
                );
              },
              icon: Icons.menu,
            ),
            const SizedBox(width: 12),
            // current location button
            MapButton(
              onTap: () {
                final currentLocation = _mapKey.currentState?.currentLocation;
                if (currentLocation != null) {
                  _mapManager.moveTo(currentLocation);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Current location not available.'),
                    ),
                  );
                }
              },
              icon: Icons.my_location,
            ),
            const SizedBox(width: 12),
            //const FilterGroupButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacePreviewPositioned() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onPlacePreviewTap,
        child: PlacePreview(placeService: _mapManager.placesService),
      ),
    );
  }

  void _onPlacePreviewTap() {
    final place = ref.read(selectedPlaceProvider);
    final markers = ref.read(markersProvider.notifier);
    final selected = markers.markerForPlace(place!);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsPage(marker: selected),
      ),
    );
  }

  void _handleMapCreated(GoogleMapController controller) {
    setState(() => _mapManager.onMapCreated(controller));
  }

  Future<void> _handlePlaceSelected(
    PlaceInformation place,
    String? sessionToken,
  ) async {
    if (!mounted) return;
    Navigator.pop(context);
    final updatedPlace = await _mapManager.moveCameraTo(
      place,
      sessionToken,
    );
    if (!mounted) return;
    if (updatedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Could not fetch place details."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _selectedPlaceName = updatedPlace.name;
      _searchController.text = _selectedPlaceName!;
    });
    // Update providers
    ref.read(selectedPlaceProvider.notifier).update(updatedPlace);
  }

  Future<LatLng?> _getCameraCenter() async {
    return await _mapManager.getCameraCenter();
  }

  void _handlePlaceTap(PlaceInformation place) {
    setState(() {
      _selectedPlaceName = place.name;
    });
    ref.read(selectedPlaceProvider.notifier).update(place);
  }
}
