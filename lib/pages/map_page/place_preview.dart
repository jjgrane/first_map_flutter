import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class PlacePreview extends StatelessWidget {
  final PlaceInformation place;
  final VoidCallback onClose;
  final PlacesService placeService;

  const PlacePreview({
    super.key,
    required this.place,
    required this.onClose,
    required this.placeService,
  });

  @override
  Widget build(BuildContext context) {
    final int maxPhotoWidth = (MediaQuery.of(context).size.width / 3).toInt();
    final double maxPhotoHeight = (MediaQuery.of(context).size.height / 4);

    return Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PLACE NAME
                        Text(
                          place.name,
                          style: TextStyle(
                            fontFamily: 'Marine',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        //const SizedBox(height: 3),
                        // DISTANCE TO LOCATION
                        Text(
                          "DISTANCE TO LOCATION",
                          style: TextStyle(
                            fontFamily: 'HalyardDisplay',
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        // Place Rating
                        if (place.rating != null)
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/google_icon.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '(${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(place.totalRatings!.toInt())})',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        // OPEN / CLOSED
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'HalyardDisplay',
                              fontWeight: FontWeight.w300,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
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

                        SizedBox(height: 8),
                        
                        // BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _actionButton("Add", Icons.add, () {}),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _actionButton(
                                "Go",
                                Icons.directions,
                                () {},
                              ),
                            ),
                            if(place.website != null)...[
                              const SizedBox(width: 4),
                              Expanded(
                                child: _actionButton(
                                  "Website",
                                  Icons.language,
                                  () => _launchWebsite(place.website!),
                                ),
                              ),
                              ]
                          ],
                        ),
                      ],
                    ),
                  ),

                  // PLACE PHOTO
                  if (place.firstPhotoRef != null) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width / 3,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          placeService.getPhotoUrl(
                            place.firstPhotoRef!,
                            maxWidth: maxPhotoWidth,
                          ),
                          fit: BoxFit.fitHeight,
                          width: maxPhotoWidth.toDouble(),   
                          height: maxPhotoHeight,                       
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
                    ),
                  ],
                ],
              ),
            ),
            // ❌ Botón de cerrar
            Positioned(
              top: -14,
              right: -14,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey,
                onPressed: onClose,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      );
  }


// Action Buttons options
  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFF134264),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
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
  print(url);
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

}
