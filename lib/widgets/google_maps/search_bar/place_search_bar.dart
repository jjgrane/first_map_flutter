import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/google_maps/search_bar/place_search_autocomplete.dart';

class PlaceSearchBar extends StatelessWidget {
  final TextEditingController textController;
  final String apiKey;
  final void Function(String) onPlaceSelected;

  const PlaceSearchBar({
    super.key,
    required this.textController,
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: PlaceSearchAutocomplete(
        textController: textController,
        apiKey: apiKey,
        onPlaceSelected: onPlaceSelected,
      ),
    );
  }
}