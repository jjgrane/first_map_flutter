import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/widgets/google_maps/map_view.dart';

class PlaceDetailsPage extends StatefulWidget {
  final PlaceInformation place;
  final GlobalKey<MapViewState> mapViewKey;
  
  const PlaceDetailsPage({
    super.key,
    required this.place,
    required this.mapViewKey,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool _isInFirestore = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkIfPlaceIsInFirestore();
  }

  Future<void> _checkIfPlaceIsInFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection('markers')
        .doc(widget.place.placeId)
        .get();

    setState(() {
      _isInFirestore = doc.exists;
      _loading = false;
    });
  }

  Future<void> _addPlace() async {
    await FirebaseFirestore.instance
        .collection('markers')
        .doc(widget.place.placeId)
        .set(widget.place.toFirestore());

    setState(() => _isInFirestore = true);
    widget.mapViewKey.currentState?.reloadMarkers();

    _showSnack("✅ Lugar agregado correctamente");
  }

  Future<void> _removePlace() async {
    await FirebaseFirestore.instance
        .collection('markers')
        .doc(widget.place.placeId)
        .delete();

    setState(() => _isInFirestore = false);
    widget.mapViewKey.currentState?.reloadMarkers();

    _showSnack("🗑️ Lugar eliminado");
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isInFirestore ? null : _addPlace,
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text("Agregar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInFirestore ? Colors.grey : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isInFirestore ? _removePlace : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Eliminar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInFirestore ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }
}
