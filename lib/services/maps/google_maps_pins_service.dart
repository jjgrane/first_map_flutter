import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:flutter/material.dart';
import 'package:first_maps_project/widgets/models/group.dart';


class GoogleMapsPinsService {

  GoogleMapsPinsService();

  /// Crea un marcador de Google Maps a partir de un MapMarker
  Future<Marker> createGoogleMarker({
    required MapMarker marker,
    Group? group,
    bool isSelected = false,
    required VoidCallback onTap,
  }) async {
    // 0. Verificar que el marcador tiene coordenadas
    if (marker.information?.location == null) {
      throw Exception('Cannot create marker without location');
    }

    /* ───────────────────── 1. Obtener el icono ───────────────────── */
    final BitmapDescriptor icon = group != null
        ? await group.getMarkerIcon(
            size:        isSelected ? 120 : 100,
            borderColor: isSelected ? Colors.blue : Colors.black,
            borderWidth: isSelected ? 3 : 2,
          )
        : BitmapDescriptor.defaultMarker;

    /* ───────────────────── 2. Construir Marker ───────────────────── */
    return Marker(
      markerId: MarkerId(marker.markerId ?? 'unknown'),
      position: marker.information!.location!,
      icon: icon,
      zIndex: isSelected ? 2 : 1,
      onTap: onTap,
    );
  }

} 