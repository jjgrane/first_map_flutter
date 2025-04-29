import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacePreview extends StatelessWidget {
  final PlaceInformation place;
  final VoidCallback onClose;
  final PlacesService placeService;

  // Reduced container height
  static const double _containerHeight = 150;
  static const double _imageSize = 100;

  const PlacePreview({
    super.key,
    required this.place,
    required this.onClose,
    required this.placeService,
  });

  @override
  Widget build(BuildContext context) {
    print(place.firstPhotoRef);
    return SizedBox(
      height: _containerHeight,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PLACE NAME (2 lines)
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Marine',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        // Tightened spacing to zero
                        const SizedBox(height: 0),
                        // DISTANCE TO LOCATION (1 line)
                        Text(
                          "DISTANCE TO LOCATION",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'HalyardDisplay',
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Place Rating (1 line)
                        if (place.rating != null) ...[
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/google_icon.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'HalyardDisplay',
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: place.rating!.toStringAsFixed(1),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: '(${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(place.totalRatings!.toInt())})',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        // OPEN / CLOSED (1 line)
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'HalyardDisplay',
                              fontWeight: FontWeight.w300,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Open',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF41AAF5),
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              TextSpan(text: 'Closes at 8PM'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton("Add", Icons.add, () {}),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _actionButton("Go", Icons.directions, () {}),
                            ),
                            if (place.website != null) ...[
                              const SizedBox(width: 4),
                              Expanded(
                                child: _actionButton(
                                  "Website",
                                  Icons.language,
                                  () => _launchWebsite(place.website!),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // PLACE PHOTO (square)
                  if (place.firstPhotoRef != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        placeService.getPhotoUrl(
                          place.firstPhotoRef!,
                          maxWidth: _imageSize.toInt(),
                        ),
                        width: _imageSize,
                        height: _imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: _imageSize,
                          height: _imageSize,
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
            ),
            // CLOSE BUTTON
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey,
                onPressed: onClose,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Buttons options
  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF134264),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'HalyardDisplay',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWebsite(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
