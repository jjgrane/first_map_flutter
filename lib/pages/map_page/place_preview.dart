import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/services/places_service.dart';

class PlacePreview extends StatelessWidget {
  final PlaceInformation place;
  final VoidCallback onExpand;
  final VoidCallback onClose;
  final PlacesService placeService;

  const PlacePreview({
    super.key,
    required this.place,
    required this.onExpand,
    required this.onClose,
    required this.placeService,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 8,
                        ), // espacio para el botón de cerrar
                        // PLACE NAME
                        Text(
                          place.name,
                          style: TextStyle(
                            fontFamily: 'HalyardDisplay',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // PLACE ADDRESS
                        Text(
                          place.address ?? "Sin dirección",
                          style: TextStyle(
                            fontFamily: 'HalyardDisplay',
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (place.firstPhotoRef != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        placeService.getPhotoUrl(
                          place.firstPhotoRef!,
                          maxWidth: 100,
                        ),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                ],
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
      ),
    );
  }
}
