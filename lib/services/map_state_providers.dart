import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:first_maps_project/services/firebase_markers_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;

/// Provider for the active map (MapInfo)
final activeMapProvider = StateProvider<MapInfo?>((ref) => null);

/// Provider for the list of places (markers) in the active map
final mapMarkersProvider = FutureProvider<List<MapMarker>>((ref) async {
  final map = ref.watch(activeMapProvider);
  if (map == null || map.id == null) return [];
  final markersService = FirebaseMarkersService();
  return await markersService.getMarkersByMapId(map.id!);
});

/// Provider for the selected place (PlaceInformation?)
final selectedPlaceProvider = StateProvider<PlaceInformation?>((ref) => null); 

/// Provider for the selected marker (MapMarker?)
final selectedMarkerProvider = StateProvider<MapMarker?>((ref) => null); 

/// Cached provider that converts MapMarkers to Google Maps Markers efficiently
final googleMapMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  print('googleMapMarkersProvider - Iniciando conversión de marcadores');
  final markersAsync = ref.watch(mapMarkersProvider);
  final selectedMarker = ref.watch(selectedMarkerProvider);
  final iconService = ref.watch(markerIconsProvider.notifier);
  
  return markersAsync.when(
    data: (markers) async {
      print('googleMapMarkersProvider - Procesando ${markers.length} marcadores');
      final Set<Marker> markerSet = {};
      
      // Add regular markers
      for (final marker in markers) {
        if (marker.information?.location != null) {
          print('googleMapMarkersProvider - Procesando marcador ${marker.markerId} con pinIcon: ${marker.pinIcon}');
          final icon = await iconService.getOrCreateIcon(marker.pinIcon);
          print('googleMapMarkersProvider - Ícono obtenido para ${marker.markerId}');
          markerSet.add(
            Marker(
              markerId: MarkerId(marker.markerId ?? 'unknown'),
              position: marker.information!.location!,
              icon: icon,
              zIndex: 1,
            ),
          );
        }
      }
      
      // Add selected marker with different style if it exists
      if (selectedMarker?.information?.location != null) {
        print('googleMapMarkersProvider - Procesando marcador seleccionado ${selectedMarker!.markerId} con pinIcon: ${selectedMarker.pinIcon}');
        final icon = await iconService.getOrCreateIcon(selectedMarker.pinIcon);
        print('googleMapMarkersProvider - Ícono obtenido para marcador seleccionado');
        markerSet.add(
          Marker(
            markerId: MarkerId(selectedMarker.markerId ?? 'unknown'),
            position: selectedMarker.information!.location!,
            icon: icon,
            zIndex: 2, // Ensure selected marker appears on top
          ),
        );
      }
      
      print('googleMapMarkersProvider - Total de marcadores convertidos: ${markerSet.length}');
      return markerSet;
    },
    loading: () {
      print('googleMapMarkersProvider - Estado: loading');
      return <Marker>{};
    },
    error: (error, stack) {
      print('googleMapMarkersProvider - Error: $error');
      return <Marker>{};
    },
  );
}); 

/// Provider for marker icons cache
final markerIconsProvider = StateNotifierProvider<MarkerIconsNotifier, Map<String, BitmapDescriptor>>((ref) {
  return MarkerIconsNotifier();
});

/// Notifier to manage marker icons
class MarkerIconsNotifier extends StateNotifier<Map<String, BitmapDescriptor>> {
  MarkerIconsNotifier() : super({});

  Future<BitmapDescriptor> getOrCreateIcon(String iconKey) async {
    print('MarkerIconsNotifier - getOrCreateIcon llamado con iconKey: $iconKey');
    print('MarkerIconsNotifier - Estado actual del caché: ${state.keys.toList()}');
    
    if (state.containsKey(iconKey)) {
      print('MarkerIconsNotifier - Ícono encontrado en caché para: $iconKey');
      return state[iconKey]!;
    }

    print('MarkerIconsNotifier - Creando nuevo ícono para: $iconKey');
    // Create icon based on type
    late BitmapDescriptor icon;
    if (iconKey.startsWith('emoji:')) {
      print('MarkerIconsNotifier - Creando ícono emoji: ${iconKey.substring(6)}');
      icon = await _createEmojiMarker(iconKey.substring(6));
    } else {
      print('MarkerIconsNotifier - Usando ícono default para: $iconKey');
      icon = BitmapDescriptor.defaultMarker;
    }

    print('MarkerIconsNotifier - Guardando ícono en caché para: $iconKey');
    state = Map.from(state)..[iconKey] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _createEmojiMarker(String emoji, {int size = 64}) async {
    print('MarkerIconsNotifier - _createEmojiMarker iniciado para emoji: $emoji');
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final borderPaint = ui.Paint()
      ..color = const Color(0xFF41AAF5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    final fillPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    final radius = size / 2 - borderPaint.strokeWidth / 2;
    final center = ui.Offset(size / 2, size / 2);

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: emoji,
        style: painting.TextStyle(fontSize: radius * 1.2),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final offset = ui.Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    print('MarkerIconsNotifier - _createEmojiMarker completado para emoji: $emoji');
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
