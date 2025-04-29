import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/services/firebase_markers_service.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapView extends StatefulWidget {
  final String currentMapId;
  final Function(GoogleMapController) onMapCreated;
  final void Function(PlaceInformation) onPlaceSelected;
  final Marker? selectedMarker;

  const MapView({
    super.key,
    required this.currentMapId,
    required this.onMapCreated,
    required this.onPlaceSelected,
    this.selectedMarker,
  });

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  Key _googleMapKey = UniqueKey();

  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  final Location _locationController = Location();
  String? _mapStyle;
  List<PlaceInformation> _detailsList = [];
  List<MapMarker> _markerModels = [];

  final FirebaseMarkersService _markersService = FirebaseMarkersService();

  // Valor por defecto (puede ser tu centro de referencia)
  static const LatLng _defaultCenter = LatLng(-34.5928772, -58.3780337);

  @override
  void reassemble() {
    super.reassemble();
    // Flutter calls reassemble() on hot-reload.
    // By swapping the key here, we force a one-time tear-down & rebuild.
    setState(() {
      _googleMapKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkersFromFirestore(widget.currentMapId);
    _getLocationUpdates();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
  }

  @override
  Widget build(BuildContext context) {
    // defino el punto de inicio de la camara
    LatLng cameraTarget;
    if (_currentLocation != null) {
      cameraTarget = _currentLocation!;
    } else if (_markers.isNotEmpty) {
      cameraTarget = _markers.first.position;
    } else {
      cameraTarget = _defaultCenter;
    }

    final allMarkers = {
      ..._markers,
      if (widget.selectedMarker != null) widget.selectedMarker!,
    };

    return GoogleMap(
      key: _googleMapKey,
      onMapCreated: (GoogleMapController controller) {
        widget.onMapCreated(controller); // Send controller to parent
      },
      initialCameraPosition: CameraPosition(target: cameraTarget, zoom: 13),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      markers: allMarkers,
      style: _mapStyle,
    );
  }

  Future<void> _loadMarkersFromFirestore(String mapId) async {
    // 1. fetch marker records for this map
    final markerList = await _markersService.getMarkersByMapId(
      mapId,
    );
    // 2. extract details IDs
    final detailIds = markerList.map((m) => m.detailsId).toSet().toList();
    // 3. fetch place details in batch from Firestore
    List<PlaceInformation> detailsList = [];
    if (detailIds.isNotEmpty) {
      final detailSnaps =
          await FirebaseFirestore.instance
              .collection('place_details')
              .where(FieldPath.documentId, whereIn: detailIds)
              .get();
      detailsList =
          detailSnaps.docs
              .map((doc) => PlaceInformation.fromFirestore(doc.data(), doc.id))
              .toList();
    }
    // 4. Enrich each MapMarker with its PlaceInformation
    final detailsMap = {for (var d in detailsList) d.placeId: d};
    final enrichedMarkers =
        markerList.map((m) {
          final info = detailsMap[m.detailsId];
          return MapMarker(
            markerId: m.markerId,
            detailsId: m.detailsId,
            mapId: m.mapId,
            information: info,
          );
        }).toList();
    // Store detailsList in state
    setState(() {
      _detailsList = detailsList;
      _markerModels = enrichedMarkers;
    });
    // 5. Build Google Map Marker widgets via the model's toMarker(), filtering nulls
    final newMarkers =
        enrichedMarkers.map((m) => m.toMarker(widget.onPlaceSelected)).whereType<Marker>().toSet();
    // Use helper to update markers
    _updateMarkers(newMarkers);
  }

  /// Updates the visible markers set and triggers rebuild
  void _updateMarkers(Set<Marker> newMarkers) {
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  void addMarker(MapMarker mapMarker) {
    setState(() {
      _markers.add(mapMarker.toMarker(widget.onPlaceSelected)!);
      _markerModels.add(mapMarker);
      _detailsList.add(mapMarker.information!);
    });
  }

  void removeMarkerById(String markerId) {
    final marker = _markerModels.firstWhere((mm) => mm.markerId == markerId);
    final detailId = marker.detailsId;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == markerId);
      _markerModels.removeWhere((m) => m.markerId == markerId);
      _detailsList.removeWhere((d) => d.placeId == detailId);
    });
  }

  /// Check if a placeId corresponds to an active marker; returns markerId or false
  String? getMarkerIdForPlace(String placeId) {
    try {
      final m = _markerModels.firstWhere((mm) => mm.detailsId == placeId);
      return m.markerId;
    } catch (_) {
      return null;
    }
  }

  void _getLocationUpdates() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted =
        await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        setState(() {
          _currentLocation = newLocation;
        });
      }
    });
  }

  Future<void> reloadMarkers(String mapId) async {
    await _loadMarkersFromFirestore(mapId);
  }
}
