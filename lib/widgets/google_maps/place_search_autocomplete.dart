import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/place_information.dart';

class PlaceSearchAutocomplete extends StatefulWidget {
  final TextEditingController textController;
  final String apiKey;
  final LatLng cameraCenter;
  final void Function(PlaceInformation) onPlaceSelected;


  const PlaceSearchAutocomplete({
    super.key,
    required this.textController,
    required this.apiKey,
    required this.cameraCenter,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceSearchAutocomplete> createState() =>
      _PlaceSearchAutocompleteState();
}

class _PlaceSearchAutocompleteState extends State<PlaceSearchAutocomplete> {
  String _lastInput = '';

  @override
  Widget build(BuildContext context) {
    final placesService = PlacesService(widget.apiKey);

    return TypeAheadField<PlaceInformation>(
      suggestionsCallback: (_) async {
        if (_lastInput.trim().isEmpty) return [];
        return await placesService.getAutocomplete(_lastInput, widget.cameraCenter);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(suggestion.name),
        );
      },
      onSelected: (suggestion) {
        widget.textController.text = suggestion.name;
        widget.onPlaceSelected(suggestion);
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (text) {
            setState(() {
              _lastInput = text;
            });
          },
          decoration: const InputDecoration.collapsed(
            hintText: 'Search...',
          ),
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
        );
      },
    );
  }
}
