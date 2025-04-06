import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/widgets/google_maps/place_search_autocomplete.dart';

class PlaceSearchScreen extends StatefulWidget {
  final String apiKey;
  final LatLng cameraCenter;
  final TextEditingController textController;
  final void Function(PlaceInformation) onPlaceSelected;

  const PlaceSearchScreen({
    super.key,
    required this.apiKey,
    required this.cameraCenter,
    required this.textController,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar lugar"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: PlaceSearchAutocomplete(
        textController: widget.textController,
        apiKey: widget.apiKey,
        onPlaceSelected: widget.onPlaceSelected,
        cameraCenter: widget.cameraCenter,
      ),
    );
  }
}
