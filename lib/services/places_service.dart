import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/place_information.dart';

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<PlaceInformation>> getAutocomplete(
    //https://developers.google.com/maps/documentation/places/web-service/autocomplete?hl=es-419
    String input,
    String sessionToken,
    LatLng? location,
  ) async {
    print(sessionToken);
    final locationParam =
        location != null
            ? '&location=${location.latitude},${location.longitude}&radius=3000'
            : '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$apiKey'
      '&language=es' //REVISAR ESTO MAS ADELANTE
      '&sessiontoken=$sessionToken'
      '$locationParam',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final predictions = json['predictions'] as List;
      return predictions
          .where(
            (p) =>
                p['structured_formatting']?['main_text'] != null &&
                p['place_id'] != null,
          )
          .map(
            (p) => PlaceInformation(
              name: p['structured_formatting']['main_text'],
              formattedAddress: p['structured_formatting']['secondary_text'],
              placeId: p['place_id'],
            ),
          )
          .toList();
    } else {
      return [];
    }
  }

  Future<PlaceInformation?> getPlaceDetails(
    String placeId,
    String? sessionToken,
  ) async {
    //https://developers.google.com/maps/documentation/places/web-service/details?hl=es-419
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );
    print(sessionToken);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        final result = json['result'];
        final location = result['geometry']['location'];
        final photoReferences =
            (result['photos'] as List?)
                ?.map((photo) => photo['photo_reference'] as String)
                .toList() ??
            [];
        final firstPhotoRef = photoReferences?.isNotEmpty == true ? photoReferences!.first : null;

        return PlaceInformation(
          name: result['name'],
          placeId: placeId,
          address: result['formatted_address'],
          location: LatLng(location['lat'], location['lng']),
          firstPhotoRef: firstPhotoRef, 
        );
      }
    }
    return null;
  }

String getPhotoUrl(String photoReference, {int maxWidth = 300}) {
  return 'https://maps.googleapis.com/maps/api/place/photo'
         '?maxwidth=$maxWidth'
         '&photoreference=$photoReference'
         '&key=$apiKey';
}

}
