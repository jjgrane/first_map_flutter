import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:first_maps_project/services/api/maps_api_service.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';

void main() {
  group('MapsApiService', () {
    late MapsApiService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('', 404);
      });
      service = MapsApiService(httpClient: mockClient);
    });

    tearDown(() {
      service.dispose();
    });

    group('createMap', () {
      test('should create map successfully', () async {
        // Arrange
        final newMap = MapInfo(
          name: 'Test Map',
          owner: 'test@example.com',
        );

        final responseData = {
          'id': 'map123',
          'name': 'Test Map',
          'owner': 'test@example.com',
        };

        mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/maps');
          expect(request.headers['Content-Type'], contains('application/json'));
          
          final body = jsonDecode(request.body);
          expect(body['name'], 'Test Map');
          expect(body['owner'], 'test@example.com');
          
          return http.Response(jsonEncode(responseData), 201);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.createMap(newMap);

        // Assert
        expect(result.id, 'map123');
        expect(result.name, 'Test Map');
        expect(result.owner, 'test@example.com');
      });

      test('should throw exception on error', () async {
        // Arrange
        final newMap = MapInfo(
          name: 'Test Map',
          owner: 'test@example.com',
        );

        mockClient = MockClient((request) async {
          return http.Response('{"message": "Server error"}', 500);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act & Assert
        expect(
          () => service.createMap(newMap),
          throwsException,
        );
      });
    });

    group('fetchMaps', () {
      test('should fetch all maps successfully', () async {
        // Arrange
        final responseData = [
          {
            'id': 'map1',
            'name': 'Map 1',
            'owner': 'user1@example.com',
          },
          {
            'id': 'map2',
            'name': 'Map 2',
            'owner': 'user2@example.com',
          },
        ];

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/maps');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMaps();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, 'map1');
        expect(result[0].name, 'Map 1');
        expect(result[1].id, 'map2');
        expect(result[1].name, 'Map 2');
      });

      test('should return empty list when no maps', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMaps();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('fetchMapById', () {
      test('should fetch map by ID', () async {
        // Arrange
        final responseData = {
          'id': 'map123',
          'name': 'Test Map',
          'owner': 'test@example.com',
        };

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/maps/map123');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMapById('map123');

        // Assert
        expect(result?.id, 'map123');
        expect(result?.name, 'Test Map');
        expect(result?.owner, 'test@example.com');
      });

      test('should return null when map not found', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Not found"}', 404);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMapById('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateMap', () {
      test('should update map successfully', () async {
        // Arrange
        final mapToUpdate = MapInfo(
          id: 'map123',
          name: 'Updated Map Name',
          owner: 'test@example.com',
        );

        final responseData = {
          'id': 'map123',
          'name': 'Updated Map Name',
          'owner': 'test@example.com',
        };

        mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/maps/map123');
          
          final body = jsonDecode(request.body);
          expect(body['name'], 'Updated Map Name');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.updateMap(mapToUpdate);

        // Assert
        expect(result.id, 'map123');
        expect(result.name, 'Updated Map Name');
      });

      test('should throw error when updating map without ID', () async {
        // Arrange
        final mapWithoutId = MapInfo(
          name: 'Test Map',
          owner: 'test@example.com',
        );

        // Act & Assert
        expect(
          () => service.updateMap(mapWithoutId),
          throwsArgumentError,
        );
      });
    });

    group('deleteMap', () {
      test('should delete map successfully', () async {
        // Arrange
        mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/maps/map123');
          
          return http.Response('', 204);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act & Assert
        await expectLater(
          service.deleteMap('map123'),
          completes,
        );
      });

      test('should throw exception on error', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Server error"}', 500);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act & Assert
        expect(
          () => service.deleteMap('map123'),
          throwsException,
        );
      });
    });

    group('mapExists', () {
      test('should return true when map exists', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response(jsonEncode({
            'id': 'map123',
            'name': 'Test Map',
            'owner': 'test@example.com',
          }), 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.mapExists('map123');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when map does not exist', () async {
        // Arrange
        mockClient = MockClient((request) async {
          return http.Response('{"message": "Not found"}', 404);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.mapExists('nonexistent');

        // Assert
        expect(result, isFalse);
      });
    });

    group('fetchMapsByOwner', () {
      test('should fetch maps by owner', () async {
        // Arrange
        final responseData = [
          {
            'id': 'map1',
            'name': 'Map 1',
            'owner': 'test@example.com',
          },
          {
            'id': 'map2',
            'name': 'Map 2',
            'owner': 'test@example.com',
          },
        ];

        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/maps');
          expect(request.url.queryParameters['owner'], 'test@example.com');
          
          return http.Response(jsonEncode(responseData), 200);
        });

        service = MapsApiService(httpClient: mockClient);

        // Act
        final result = await service.fetchMapsByOwner('test@example.com');

        // Assert
        expect(result.length, 2);
        expect(result[0].owner, 'test@example.com');
        expect(result[1].owner, 'test@example.com');
      });
    });
  });
} 