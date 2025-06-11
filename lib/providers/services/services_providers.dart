import 'package:first_maps_project/services/maps/emoji_marker_converter.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_markers_service.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_maps_service.dart';
import 'package:first_maps_project/services/firebase/maps/firebase_groups_service.dart';
import 'package:first_maps_project/services/maps/google_maps_pins_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Service Providers
// =============================================================================

final markerConverterProvider = Provider<EmojiMarkerConverter>((ref) {
  return EmojiMarkerConverter();
});

final firebaseMarkersServiceProvider = Provider<FirebaseMarkersService>((ref) {
  return FirebaseMarkersService();
});

final firebaseGroupsServiceProvider = Provider<FirebaseGroupsService>((ref) {
  return FirebaseGroupsService();
});

final firebaseMapsServiceProvider = Provider<FirebaseMapsService>((ref) {
  return FirebaseMapsService();
});

final googleMapsPinsServiceProvider = Provider<GoogleMapsPinsService>((ref) {
  return GoogleMapsPinsService();
});
