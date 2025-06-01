import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:first_maps_project/services/api/markers_api_service.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/widgets/models/place_information.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('MarkersApiService', () {
    late MarkersApiService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('', 404);
      });
      service = MarkersApiService(httpClient: mockClient);
    });

    tearDown(() {
      service.dispose();
    });

    group('createMarker', () {
      test('should create marker successfully', () async {
        // Arrange
        final newMarker = MapMarker(
          detailsId: 'details123',
          mapId: 'map123',
          groupId: 'group123',
          information: PlaceInformation(
            placeId: 'place123',
            name: 'Test Place',
            address: '123 Test St',
            location: const LatLng(37.7749, -122.4194),
          ),
        );

        final responseData = {
          'marker_id': 'marker123',
          'details_id': 'details123',
          'map_id': 'map123',
          'group_id': 'group123',
          'information': {
            'place_id': 'place123',
            'name': 'Test Place',
            'address': '123 Test St',
            'location': {
              'latitude': 37.7749,
              'longitude': -122.4194,
            },
          },
        };

        mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/markers');
          expect(request.headers['Content-Type'], contains('application/json'));
          
          final body = jsonDecode(request.body);
          expect(body['details_id'], 'details123');
          expect(body['map_id'], 'map123');
          
          return http.Response(jsonEncode(responseData), 201);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.createMarker(newMarker);

        // Assert
        expect(result.markerId, 'marker123');
        expect(result.detailsId, 'details123');
        expect(result.mapId, 'map123');
        expect(result.groupId, 'group123');
        expect(result.information?.name, 'Test Place');
      });

      test('should throw exception on error', () async {
        // Arrange
        final newMarker = MapMarker(
          detailsId: 'details123',
          mapId: 'map123',
        );

        mockClient = MockClient((request) async {
          return http.Response('{"message": "Server error"}', 500);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act & Assert
        expect(
          () => service.createMarker(newMarker),
          throwsException,
        );
      });
    });

    group('fetchMarkers', () {
      test('should fetch all markers successfully', () async {
        // Arrange
        final responseData = [
          {
            'marker_id': 'marker1',
            'details_id': 'details1',
            'map_id': 'map1',
          },
          {
            'marker_id': 'marker2',
            'details_id': 'details2',
            'map_id': 'map2',
          },
        ];

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/markers');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkers();

        // Assert
        expect(result.length, 2);
        expect(result[0].markerId, 'marker1');
        expect(result[1].markerId, 'marker2');
      });

      test('should return empty list when no markers', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkers();

        // Assert
        expect(result, isEmpty);
      });

      test('should fetch markers for map test_map_id successfully', () async {
        // Arrange
        final responseData = [
          {
            'marker_id': 'test_marker_1',
            'details_id': 'test_details_1',
            'map_id': 'test_map_id',
            'information': {
              'place_id': 'place_1',
              'name': 'Test Location 1',
              'address': '100 Test Street',
              'location': {
                'latitude': 37.7749,
                'longitude': -122.4194,
              },
              'rating': 4.2,
              'total_ratings': 150,
            }
          },
          {
            'marker_id': 'test_marker_2',
            'details_id': 'test_details_2',
            'map_id': 'test_map_id',
            'information': {
              'place_id': 'place_2',
              'name': 'Test Location 2',
              'address': '200 Sample Avenue',
              'location': {
                'latitude': 37.7849,
                'longitude': -122.4094,
              },
            }
          },
          {
            'marker_id': 'test_marker_3',
            'details_id': 'test_details_3',
            'map_id': 'test_map_id',
            // No information field to test partial data
          },
        ];

        mockClient = MockClient((request) async {
          // Assert request is made correctly
          expect(request.method, 'GET');
          expect(request.url.path, '/markers');
          expect(request.headers['Accept'], 'application/json');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkers();

        // Assert - verify the response is parsed correctly
        expect(result, isNotNull);
        expect(result, isNotEmpty);
        expect(result.length, 3);
        
        // Assert all markers belong to test_map_id
        expect(result.every((marker) => marker.mapId == 'test_map_id'), isTrue);
        
        // Verify first marker details
        final firstMarker = result[0];
        expect(firstMarker.markerId, 'test_marker_1');
        expect(firstMarker.detailsId, 'test_details_1');
        expect(firstMarker.mapId, 'test_map_id');
        expect(firstMarker.information, isNotNull);
        expect(firstMarker.information!.placeId, 'place_1');
        expect(firstMarker.information!.name, 'Test Location 1');
        expect(firstMarker.information!.address, '100 Test Street');
        expect(firstMarker.information!.location, isNotNull);
        expect(firstMarker.information!.location!.latitude, 37.7749);
        expect(firstMarker.information!.location!.longitude, -122.4194);
        expect(firstMarker.information!.rating, 4.2);
        expect(firstMarker.information!.totalRatings, 150);
        
        // Verify second marker has partial information
        final secondMarker = result[1];
        expect(secondMarker.markerId, 'test_marker_2');
        expect(secondMarker.information, isNotNull);
        expect(secondMarker.information!.name, 'Test Location 2');
        expect(secondMarker.information!.rating, isNull); // No rating provided
        
        // Verify third marker has no information
        final thirdMarker = result[2];
        expect(thirdMarker.markerId, 'test_marker_3');
        expect(thirdMarker.information, isNull);
        
        // No group assertions as groups are handled by Firebase
        expect(firstMarker.groupId, isNull);
        expect(secondMarker.groupId, isNull);
        expect(thirdMarker.groupId, isNull);
      });
    });

    group('fetchMarkersByMapId', () {
      test('should fetch markers for specific map', () async {
        // Arrange
        final responseData = [
          {
            'marker_id': 'marker1',
            'details_id': 'details1',
            'map_id': 'map123',
          },
        ];

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/markers');
          expect(request.url.queryParameters['map_id'], 'map123');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkersByMapId('map123');

        // Assert
        expect(result.length, 1);
        expect(result[0].mapId, 'map123');
      });
    });

    group('fetchMarkerById', () {
      test('should fetch marker by ID', () async {
        // Arrange
        final responseData = {
          'marker_id': 'marker123',
          'details_id': 'details123',
          'map_id': 'map123',
        };

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/markers/marker123');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkerById('marker123');

        // Assert
        expect(result?.markerId, 'marker123');
      });

      test('should return null when marker not found', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Not found"}', 404);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMarkerById('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('deleteMarker', () {
      test('should delete marker successfully', () async {
        // Arrange
        mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/markers/marker123');
          
          return http.Response('', 204);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act & Assert
        await expectLater(
          service.deleteMarker('marker123'),
          completes,
        );
      });

      test('should throw exception on error', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Server error"}', 500);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act & Assert
        expect(
          () => service.deleteMarker('marker123'),
          throwsException,
        );
      });
    });

    group('updateMarkerGroup', () {
      test('should update marker group successfully', () async {
        // Arrange
        mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/markers/marker123');
          
          final body = jsonDecode(request.body);
          expect(body['group_id'], 'newGroup123');
          
          return http.Response(jsonEncode({
            'marker_id': 'marker123',
            'details_id': 'details123',
            'map_id': 'map123',
            'group_id': 'newGroup123',
          }), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act & Assert
        await expectLater(
          service.updateMarkerGroup('marker123', 'newGroup123'),
          completes,
        );
      });
    });

    group('markerExists', () {
      test('should return true when marker exists', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response(jsonEncode({
            'marker_id': 'marker123',
            'details_id': 'details123',
            'map_id': 'map123',
          }), 200);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.markerExists('marker123');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when marker does not exist', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Not found"}', 404);
        });

        service = MarkersApiService(httpClient: mockClient);

        // Act
        final result = await service.markerExists('nonexistent');

        // Assert
        expect(result, isFalse);
      });
    });
  });
} 