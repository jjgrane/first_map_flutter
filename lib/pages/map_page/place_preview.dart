import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/pages/map_page/groups_view_page.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:first_maps_project/providers/map_providers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacePreview extends ConsumerStatefulWidget {
  final PlacesService placeService;

  const PlacePreview({
    super.key,
    required this.placeService,
  });

  @override
  ConsumerState<PlacePreview> createState() => _PlacePreviewState();
}

class _PlacePreviewState extends ConsumerState<PlacePreview> with SingleTickerProviderStateMixin {
  // Reduced container height
  static const double _containerHeight = 150;
  static const double _imageSize = 100;
  
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(selectedPlaceProvider);
    
    // Manejar la animación basada en si hay un lugar seleccionado
    if (place == null) {
      _controller.reverse();
    } else {
      _controller.forward();
    }

    // Observar el marcador actual
    final currentMarker = ref.watch(selectedMarkerProvider);
    final isSaved = currentMarker?.markerId != null;
    final savedIcon = currentMarker?.pinIcon;

    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1,
      child: SizedBox(
      height: _containerHeight,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Stack(
          children: [
              if (place != null) Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Marine',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 0),
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
                                        const WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
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
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                            text: const TextSpan(
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                isSaved ? (savedIcon ?? '') : 'Add',
                                isSaved ? null : Icons.add,
                                  () => _onAddTapped(currentMarker),
                                  backgroundColor: isSaved 
                                        ? Colors.orange
                                        : const Color(0xFF134264),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _actionButton(
                                "Go",
                                Icons.directions,
                                () {},
                              ),
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
                    if (place.firstPhotoRef != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                          widget.placeService.getPhotoUrl(
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
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey,
                  onPressed: () => ref.read(selectedPlaceProvider.notifier).clear(),
                splashRadius: 20,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddTapped(MapMarker? currentMarker) async {
    final result = await Navigator.push<MapMarker?>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupsViewPage(currentMarker: currentMarker),
      ),
    );
    
    if (result != null) {
      // Update the marker in the state
      if (result.markerId != null) {
        await ref.read(markersStateProvider.notifier).updateMarker(result);
      } else {
        await ref.read(markersStateProvider.notifier).addMarker(result);
      }
    }
  }

  Widget _actionButton(
    String label,
    IconData? icon,
    VoidCallback onTap, {
    Color backgroundColor = const Color(0xFF134264),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 14, color: Colors.white),
            if (icon != null && label != '')
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
