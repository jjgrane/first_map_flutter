import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/pages/map_page/place_search_bar.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_maps_service.dart';
import 'package:first_maps_project/services/maps/places_service.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';
import 'package:first_maps_project/pages/place_details_page.dart';
import 'package:first_maps_project/pages/map_page/place_preview.dart';
import 'package:first_maps_project/pages/search_page/search_page.dart';
import 'package:first_maps_project/pages/map_page/map_selection_page.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:first_maps_project/pages/map_page/map_places_list_view.dart';
import 'package:first_maps_project/pages/map_page/map_button.dart';
import 'package:first_maps_project/services/maps/map_manager.dart';
import 'package:location/location.dart';
import 'package:first_maps_project/widgets/google_maps/filter_group_buttons.dart';

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

  // Map Manager
  late final MapManager _mapManager;

  // Map State
  String? _currentMapName;
  String? _selectedPlaceName;

  @override
  void initState() {
    super.initState();
    _mapManager = MapManager();
    _loadDefaultMap();
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
        Consumer(
          builder: (context, ref, _) {
            final isPreviewVisible = ref.watch(selectedMarkerProvider) != null;
            final double baseMargin = 40;
            final double previewOffset = isPreviewVisible ? (24 + 140) : 0;
            return Positioned(
              bottom: baseMargin + previewOffset,
              right: 10,
              child: SizedBox(
                height: 3000.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MapButton(onTap: _onMapsButtonTap, icon: Icons.map),
                    const SizedBox(width: 12),
                    MapButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapPlacesListView(),
                          ),
                        );
                      },
                      icon: Icons.menu,
                    ),
                    const SizedBox(width: 12),
                    MapButton(
                      onTap: () {
                        final currentLocation =
                            _mapKey.currentState?.currentLocation;
                        if (currentLocation != null) {
                          _mapManager.moveTo(currentLocation);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Current location not available.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icons.my_location,
                    ),
                    const SizedBox(width: 12),
                    const FilterGroupButtons(),
                  ],
                ),
              ),
            );
          },
        ),
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
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlaceDetailsPage()),
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
    final updatedPlace = await _mapManager.handlePlaceSelected(
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
    if (context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(selectedPlaceProvider.notifier).update(updatedPlace);
    }
  }

  Future<LatLng?> _getCameraCenter() async {
    return await _mapManager.getCameraCenter();
  }

  Future<void> _loadDefaultMap() async {
    final def = await _mapManager.loadDefaultMap();
    if (def == null) return;
    setState(() {
      _currentMapName = def.name;
    });
    if (context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(activeMapProvider.notifier).state = def;
    }
  }

  void _handlePlaceTap(PlaceInformation place) {
    setState(() {
      _selectedPlaceName = place.name;
    });
    if (context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(selectedPlaceProvider.notifier).update(place);
    }
  }

  Future<void> _onMapsButtonTap() async {
    if (!mounted) return;
    final selected = await Navigator.push<MapInfo>(
      context,
      MaterialPageRoute(builder: (_) => MapSelectionPage()),
    );
    if (selected != null) {
      setState(() {
        _currentMapName = selected.name;
      });
      if (context.mounted) {
        final container = ProviderScope.containerOf(context);
        container.read(activeMapProvider.notifier).state = selected;
      }
    }
  }
}
