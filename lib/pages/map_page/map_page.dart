import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/pages/map_page/place_search_bar.dart';
import 'package:first_maps_project/services/firebase_maps_service.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/pages/place_details_page.dart';
import 'package:first_maps_project/pages/map_page/place_preview.dart';
import 'package:first_maps_project/pages/search_page/search_page.dart';
import 'package:first_maps_project/pages/map_page/map_selection_page.dart';
import 'package:first_maps_project/providers/map_providers.dart';

// Main page displaying the Google Map and related overlays
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Keys and Controllers
  final GlobalKey<MapViewState> _mapKey = GlobalKey<MapViewState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  GoogleMapController? _mapController;

  // Services
  final FirebaseMapsService _mapsService = FirebaseMapsService();
  late final PlacesService _placesService;

  // Map State
  String? _currentMapId;
  String? _currentMapName;
  String? _selectedPlaceName;

  // UI State
  final ValueNotifier<bool> _isPreviewVisible = ValueNotifier<bool>(false);

  // Configuration
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  @override
  void initState() {
    super.initState();
    // Initialize the PlacesService and load the default map info
    _placesService = PlacesService(_googleApiKey);
    _loadDefaultMap();
  }

  @override
  void dispose() {
    // Clean up controllers to avoid memory leaks
    _searchController.dispose();
    _searchFocusNode.dispose();
    _isPreviewVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build main scaffold with map and overlays
    return Scaffold(body: _buildMapStack());
  }

  // Widget displayed while loading default map
  Widget _buildLoading() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // Stack containing the map view and overlay widgets
  Widget _buildMapStack() {
    return Stack(
      children: [
        _buildMapView(),
        _buildSearchBar(),
        _buildMapsButton(),
        _buildPlacePreviewPositioned(),
      ],
    );
  }

  // Core MapView widget displaying Google Map
  Widget _buildMapView() {
    return MapView(
      key: _mapKey,
      onMapCreated: _handleMapCreated,
      onPlaceSelected: _handlePlaceTap,
    );
  }

  // Search bar overlay at the top of the map
  Widget _buildSearchBar() {
    return PlaceSearchBar(
      displayText: _selectedPlaceName ?? _currentMapName ?? '',
      onTap: () async {
        // Get current map center and open search page
        final cameraCenter = await _getCameraCenter();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              apiKey: _googleApiKey,
              cameraCenter: cameraCenter,
              textController: _searchController,
              onPlaceSelected: _handlePlaceSelected,
            ),
          ),
        );
      },
    );
  }

  // Circular maps button positioned at the bottom, adjusts if preview is visible
  Widget _buildMapsButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPreviewVisible,
      builder: (context, isVisible, child) {
        // Base margin from bottom
        final double baseMargin = 40;
        // Height of preview slider + its bottom margin (24 + 140)
        final double previewOffset = isVisible ? (24 + 140) : 0;
        
        return Positioned(
          bottom: baseMargin + previewOffset,
          right: 10,
          child: child!,
        );
      },
      child: GestureDetector(
        onTap: _onMapsButtonTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.map, size: 24, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  // Positioned preview bar at bottom when a place is selected
  Widget _buildPlacePreviewPositioned() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onPlacePreviewTap,
        child: PlacePreview(
          placeService: _placesService,
        ),
      ),
    );
  }

  // Navigate to place details page
  void _onPlacePreviewTap() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaceDetailsPage(),
      ),
    );
  }

  // Callback when the GoogleMap is created
  void _handleMapCreated(GoogleMapController controller) {
    setState(() => _mapController = controller);
  }

  // Handle selection of a place from the search page
  Future<void> _handlePlaceSelected(
    PlaceInformation place,
    String? sessionToken,
  ) async {
    if (!mounted) return;
    Navigator.pop(context);
    PlaceInformation? updatedPlace = place;
    if (place.location == null) {
      updatedPlace = await _placesService.getPlaceDetails(
        place.placeId,
        sessionToken,
      );
    }
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
    final coords = updatedPlace.location;

    if (coords != null && _mapController != null) {
      final marker = updatedPlace.toMarker();

      if (marker != null) {
        setState(() {
          _selectedPlaceName = updatedPlace!.name;
          _searchController.text = _selectedPlaceName!;
        });
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
        
        // Update providers
        if (context.mounted) {
          final container = ProviderScope.containerOf(context);
          container.read(selectedPlaceProvider.notifier).update(updatedPlace);
        }
      }
    }
  }

  // Calculate the current center of the visible map region
  Future<LatLng> _getCameraCenter() async {
    final bounds = await _mapController!.getVisibleRegion();
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  /// Loads all maps, picks the one named "default", and updates state
  Future<void> _loadDefaultMap() async {
    final maps = await _mapsService.getAllMaps();
    final def = maps.firstWhere(
      (m) => m.name == 'default',
      orElse: () => MapInfo(id: '', name: '', owner: ''),
    );
    if (def.id!.isEmpty) return;

    // Update local state
    setState(() {
      _currentMapId = def.id;
      _currentMapName = def.name;
    });

    // Update providers
    if (context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(activeMapProvider.notifier).state = def;
    }
  }

  // Handle taps directly on the map to select a place marker
  void _handlePlaceTap(PlaceInformation place) {
    setState(() {
      _selectedPlaceName = place.name;
    });
    
    // Update providers
    if (context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(selectedPlaceProvider.notifier).update(place);
    }
  }

  // Handler for tapping the maps button: open map selection view
  Future<void> _onMapsButtonTap() async {
    if (!mounted) return;
    final selected = await Navigator.push<MapInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSelectionPage(
          mapId: _currentMapId!,
          mapName: _currentMapName!,
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _currentMapName = selected.name;
      });

      // Update providers
      if (context.mounted) {
        final container = ProviderScope.containerOf(context);
        container.read(activeMapProvider.notifier).state = selected;
      }
    }
  }
}
