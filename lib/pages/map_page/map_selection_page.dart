import 'package:flutter/material.dart';

/// Initial version of MapSelectionPage.
/// Displays current map information and provides a back button.
class MapSelectionPage extends StatelessWidget {
  /// Firestore ID of the current map
  final String mapId;

  /// Name of the current map
  final String mapName;

  const MapSelectionPage({
    super.key,
    required this.mapId,
    required this.mapName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Selection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display map ID
            Text(
              'Map ID: \$mapId',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Display map name
            Text(
              'Map Name: \$mapName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            // Back button at bottom
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
