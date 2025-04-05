import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/google_maps/search_bar/autocomplete_result.dart';

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<AutocompleteResult>> getAutocomplete(
    String input,
    LatLng? location,
  ) async {
    final locationParam =
        location != null
            ? '&location=${location.latitude},${location.longitude}&radius=30000'
            : '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$apiKey'
      '&language=es'
      '$locationParam',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final predictions = json['predictions'] as List;
      return predictions
          .where((p) => p['description'] != null && p['place_id'] != null)
          .map(
            (p) => AutocompleteResult(
              description: p['description'],
              placeId: p['place_id'],
            ),
          )
          .toList();
    } else {
      return [];
    }
  }

  Future<LatLng?> getCoordinatesFromPlaceId(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        final location = json['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        print('❗ Place Details error: ${json['status']}');
      }
    }
    return null;
  }
}
