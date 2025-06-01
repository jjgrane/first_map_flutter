import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:first_maps_project/services/api/markers_api_service.dart';
import 'package:first_maps_project/services/api/maps_api_service.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('API Integration Tests', () {
    test('Fetch map and its markers using map ID: test_map_id', () async {
      // Create a mock client that handles both map and marker requests
      final mockClient = MockClient((request) async {
        // Handle map request
        if (request.url.path == '/maps/test_map_id') {
          final mapData = {
            'id': 'test_map_id',
            'name': 'Test Map',
            'owner': 'test@example.com',
          };
          return http.Response(jsonEncode(mapData), 200);
        }
        
        // Handle markers request with map_id query parameter
        if (request.url.path == '/markers' && 
            request.url.queryParameters['map_id'] == 'test_map_id') {
          final markersData = [
            {
              'marker_id': 'marker1',
              'details_id': 'details1',
              'map_id': 'test_map_id',
              'group_id': 'group1',
              'information': {
                'place_id': 'place1',
                'name': 'Location 1',
                'address': '123 Main St',
                'location': {
                  'latitude': 37.7749,
                  'longitude': -122.4194,
                },
                'rating': 4.5,
                'total_ratings': 100,
              }
            },
            {
              'marker_id': 'marker2',
              'details_id': 'details2',
              'map_id': 'test_map_id',
              'group_id': 'group2',
              'information': {
                'place_id': 'place2',
                'name': 'Location 2',
                'address': '456 Oak Ave',
                'location': {
                  'latitude': 37.7849,
                  'longitude': -122.4094,
                },
                'rating': 4.8,
                'total_ratings': 250,
              }
            },
            {
              'marker_id': 'marker3',
              'details_id': 'details3',
              'map_id': 'test_map_id',
              'information': {
                'place_id': 'place3',
                'name': 'Location 3',
                'address': '789 Pine Blvd',
                'location': {
                  'latitude': 37.7649,
                  'longitude': -122.4294,
                },
              }
            },
          ];
          return http.Response(jsonEncode(markersData), 200);
        }
        
        // Default 404 response
        return http.Response('Not found', 404);
      });

      // Create services with the mock client
      final mapsService = MapsApiService(httpClient: mockClient);
      final markersService = MarkersApiService(httpClient: mockClient);

      // Test fetching the map
      print('\n=== Fetching Map with ID: test_map_id ===');
      final map = await mapsService.fetchMapById('test_map_id');
      
      expect(map, isNotNull);
      expect(map!.id, equals('test_map_id'));
      expect(map.name, equals('Test Map'));
      expect(map.owner, equals('test@example.com'));
      
      print('Map fetched successfully:');
      print('  ID: ${map.id}');
      print('  Name: ${map.name}');
      print('  Owner: ${map.owner}');

      // Test fetching markers for the map
      print('\n=== Fetching Markers for Map ID: test_map_id ===');
      final markers = await markersService.fetchMarkersByMapId('test_map_id');
      
      expect(markers, hasLength(3));
      expect(markers.every((m) => m.mapId == 'test_map_id'), isTrue);
      
      print('Found ${markers.length} markers:');
      for (var i = 0; i < markers.length; i++) {
        final marker = markers[i];
        print('\nMarker ${i + 1}:');
        print('  ID: ${marker.markerId}');
        print('  Details ID: ${marker.detailsId}');
        print('  Group ID: ${marker.groupId ?? "No group"}');
        
        if (marker.information != null) {
          print('  Place Info:');
          print('    Name: ${marker.information!.name}');
          print('    Address: ${marker.information!.address ?? "No address"}');
          print('    Location: ${marker.information!.location?.latitude}, ${marker.information!.location?.longitude}');
          print('    Rating: ${marker.information!.rating ?? "No rating"} (${marker.information!.totalRatings ?? 0} reviews)');
        }
      }

      // Verify specific marker details
      final firstMarker = markers[0];
      expect(firstMarker.markerId, equals('marker1'));
      expect(firstMarker.groupId, equals('group1'));
      expect(firstMarker.information?.name, equals('Location 1'));
      expect(firstMarker.information?.rating, equals(4.5));

      final secondMarker = markers[1];
      expect(secondMarker.markerId, equals('marker2'));
      expect(secondMarker.groupId, equals('group2'));
      expect(secondMarker.information?.name, equals('Location 2'));
      expect(secondMarker.information?.totalRatings, equals(250));

      final thirdMarker = markers[2];
      expect(thirdMarker.markerId, equals('marker3'));
      expect(thirdMarker.groupId, isNull); // No group_id in the data
      expect(thirdMarker.information?.rating, isNull); // No rating

      // Clean up
      mapsService.dispose();
      markersService.dispose();
    });

    test('Create and retrieve map with markers', () async {
      // This test simulates creating a new map and adding markers to it
      final createdMapId = 'new_test_map_id';
      final createdMarkerIds = <String>[];

      final mockClient = MockClient((request) async {
        // Handle map creation
        if (request.method == 'POST' && request.url.path == '/maps') {
          final body = jsonDecode(request.body);
          final responseData = {
            'id': createdMapId,
            'name': body['name'],
            'owner': body['owner'],
          };
          return http.Response(jsonEncode(responseData), 201);
        }

        // Handle marker creation
        if (request.method == 'POST' && request.url.path == '/markers') {
          final body = jsonDecode(request.body);
          final markerId = 'created_marker_${createdMarkerIds.length + 1}';
          createdMarkerIds.add(markerId);
          
          final responseData = {
            'marker_id': markerId,
            'details_id': body['details_id'],
            'map_id': body['map_id'],
            'group_id': body['group_id'],
          };
          return http.Response(jsonEncode(responseData), 201);
        }

        // Handle fetching markers by map_id
        if (request.url.path == '/markers' && 
            request.url.queryParameters['map_id'] == createdMapId) {
          final markersData = createdMarkerIds.map((id) => {
            'marker_id': id,
            'details_id': 'details_$id',
            'map_id': createdMapId,
          }).toList();
          return http.Response(jsonEncode(markersData), 200);
        }

        return http.Response('Not found', 404);
      });

      final mapsService = MapsApiService(httpClient: mockClient);
      final markersService = MarkersApiService(httpClient: mockClient);

      // Create a new map
      print('\n=== Creating a new map ===');
      final newMap = MapInfo(
        name: 'My New Test Map',
        owner: 'user@example.com',
      );
      
      final createdMap = await mapsService.createMap(newMap);
      expect(createdMap.id, equals(createdMapId));
      print('Map created with ID: ${createdMap.id}');

      // Create markers for the map
      print('\n=== Adding markers to the map ===');
      final marker1 = MapMarker(
        detailsId: 'details_location_1',
        mapId: createdMapId,
        groupId: 'restaurants',
      );
      
      final marker2 = MapMarker(
        detailsId: 'details_location_2',
        mapId: createdMapId,
        groupId: 'parks',
      );

      final createdMarker1 = await markersService.createMarker(marker1);
      final createdMarker2 = await markersService.createMarker(marker2);
      
      print('Created marker 1 with ID: ${createdMarker1.markerId}');
      print('Created marker 2 with ID: ${createdMarker2.markerId}');

      // Fetch all markers for the map
      print('\n=== Retrieving all markers for the map ===');
      final retrievedMarkers = await markersService.fetchMarkersByMapId(createdMapId);
      
      expect(retrievedMarkers, hasLength(2));
      expect(retrievedMarkers.every((m) => m.mapId == createdMapId), isTrue);
      print('Successfully retrieved ${retrievedMarkers.length} markers for map ID: $createdMapId');

      // Clean up
      mapsService.dispose();
      markersService.dispose();
    });
  });
} 