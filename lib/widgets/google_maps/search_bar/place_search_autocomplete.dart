import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/google_maps/search_bar/autocomplete_result.dart';

class PlaceSearchAutocomplete extends StatefulWidget {
  final TextEditingController textController;
  final String apiKey;
  final GoogleMapController mapController;
  final void Function(String) onPlaceSelected;
  

  const PlaceSearchAutocomplete({
    super.key,
    required this.textController,
    required this.apiKey,
    required this.mapController,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceSearchAutocomplete> createState() =>
      _PlaceSearchAutocompleteState();
}

class _PlaceSearchAutocompleteState extends State<PlaceSearchAutocomplete> {
  String _lastInput = '';
  LatLng? _cameraCenter;

  @override
  Widget build(BuildContext context) {
    final placesService = PlacesService(widget.apiKey);

    return TypeAheadField<AutocompleteResult>(
      suggestionsCallback: (_) async {
        if (_lastInput.trim().isEmpty) return [];
        if (_cameraCenter == null) await _updateCameraCenter();
        return await placesService.getAutocomplete(_lastInput, _cameraCenter);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(suggestion.description),
        );
      },
      onSelected: (suggestion) {
        widget.textController.text = suggestion.description;
        widget.onPlaceSelected(suggestion.placeId);
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onTap: _updateCameraCenter, 
          onChanged: (text) {
            setState(() {
              _lastInput = text;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Buscar lugar...',
            prefixIcon: Icon(Icons.search),
          ),
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
        );
      },
    );
  }
    Future<void> _updateCameraCenter() async {
    final bounds = await widget.mapController.getVisibleRegion();
    setState(() {
      _cameraCenter = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
    });
  }

}
