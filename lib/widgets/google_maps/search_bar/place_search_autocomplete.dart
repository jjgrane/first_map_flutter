import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:first_maps_project/services/places_service.dart';

class PlaceSearchAutocomplete extends StatefulWidget {
  final TextEditingController textController;
  final String apiKey;
  final void Function(String) onPlaceSelected;

  const PlaceSearchAutocomplete({
    super.key,
    required this.textController,
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceSearchAutocomplete> createState() => _PlaceSearchAutocompleteState();
}

class _PlaceSearchAutocompleteState extends State<PlaceSearchAutocomplete> {
  String _lastInput = '';

  @override
  Widget build(BuildContext context) {
    final placesService = PlacesService(widget.apiKey);

    return TypeAheadField<String>(
      suggestionsCallback: (_) async {
        print('💡 El usuario está escribiendo: "$_lastInput"');
        if (_lastInput.trim().isEmpty) return [];
        return await placesService.getAutocomplete(_lastInput);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        widget.textController.text = suggestion;
        widget.onPlaceSelected(suggestion);
      },
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('No se encontraron resultados'),
      ),
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, error) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Error buscando lugares'),
      ),
      builder: (context, controller, focusNode) {
        print('📥 Se renderizó el TextField');
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (text) {
            print('📲 Usuario escribió: $text');
            setState(() {
              _lastInput = text;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Buscar lugar...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
        );
      },
    );
  }
}
