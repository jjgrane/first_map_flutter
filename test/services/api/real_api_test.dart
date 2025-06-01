/// This test is meant to be run against a real API server
/// To run: dart test/services/api/real_api_test.dart
/// 
/// Make sure your API server is running at http://192.168.0.107:8080
/// 
import 'package:first_maps_project/services/api/markers_api_service.dart';
import 'package:first_maps_project/services/api/maps_api_service.dart';

void main() async {
  // Create real services (no mocks)
  final mapsService = MapsApiService();
  final markersService = MarkersApiService();

  try {
    print('Testing against real API server...\n');
    
    // Test fetching map with ID: test_map_id
    print('=== Fetching Map with ID: test_map_id ===');
    final map = await mapsService.fetchMapById('test_map_id');
    
    if (map != null) {
      print('Map found:');
      print('  ID: ${map.id}');
      print('  Name: ${map.name}');
      print('  Owner: ${map.owner}');
    } else {
      print('Map with ID "test_map_id" not found.');
    }

    // Test fetching markers for map ID: test_map_id
    print('\n=== Fetching Markers for Map ID: test_map_id ===');
    final markers = await markersService.fetchMarkersByMapId('test_map_id');
    
    if (markers.isNotEmpty) {
      print('Found ${markers.length} markers:');
      
      for (var i = 0; i < markers.length; i++) {
        final marker = markers[i];
        print('\nMarker ${i + 1}:');
        print('  ID: ${marker.markerId}');
        print('  Details ID: ${marker.detailsId}');
        print('  Map ID: ${marker.mapId}');
        print('  Group ID: ${marker.groupId ?? "No group"}');
        
        if (marker.information != null) {
          print('  Place Information:');
          print('    Name: ${marker.information!.name}');
          print('    Address: ${marker.information!.address ?? "No address"}');
          if (marker.information!.location != null) {
            print('    Location: ${marker.information!.location!.latitude}, ${marker.information!.location!.longitude}');
          }
          if (marker.information!.rating != null) {
            print('    Rating: ${marker.information!.rating} (${marker.information!.totalRatings ?? 0} reviews)');
          }
        }
      }
    } else {
      print('No markers found for map ID "test_map_id".');
    }

    // Test fetching all maps
    print('\n=== Fetching All Maps ===');
    final allMaps = await mapsService.fetchMaps();
    
    if (allMaps.isNotEmpty) {
      print('Found ${allMaps.length} maps:');
      for (final mapItem in allMaps) {
        print('  - ${mapItem.name} (ID: ${mapItem.id}, Owner: ${mapItem.owner})');
      }
    } else {
      print('No maps found.');
    }

  } catch (e) {
    print('\nError occurred: $e');
    print('\nMake sure:');
    print('1. Your API server is running at http://192.168.0.107:8080');
    print('2. The server is accessible from this device');
    print('3. The API endpoints are properly configured');
  } finally {
    // Clean up
    mapsService.dispose();
    markersService.dispose();
  }
} 