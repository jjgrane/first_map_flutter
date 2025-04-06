import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/place_information.dart';

class PlaceDetailsPage extends StatelessWidget {
  final PlaceInformation place;

  const PlaceDetailsPage({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📍 ${place.name}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              place.address ?? "no data",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              place.location != null
                  ? "🗺️ Coordenadas: ${place.location!.latitude}, ${place.location!.longitude}"
                  : "🗺️ Coordenadas: no data",
            ),
            // Agregás más datos si los tenés (tags, creador, etc.)
          ],
        ),
      ),
    );
  }
}
