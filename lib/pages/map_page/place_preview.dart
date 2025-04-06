import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/place_information.dart';

class PlacePreview extends StatelessWidget {
  final PlaceInformation place;
  final VoidCallback onExpand;
  final VoidCallback onClose; // 👈 NUEVO

  const PlacePreview({
    super.key,
    required this.place,
    required this.onExpand,
    required this.onClose, // 👈 NUEVO
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8), // espacio para el botón de cerrar
                  Text(place.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(place.address ?? "Sin dirección", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onExpand,
                      child: const Text("Ver más"),
                    ),
                  )
                ],
              ),
            ),
            // ❌ Botón de cerrar
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
