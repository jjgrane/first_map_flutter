import 'package:first_maps_project/services/api/api_client.dart';
import 'package:first_maps_project/services/api/api_endpoints.dart';
import 'package:first_maps_project/services/api/api_response.dart';
import 'package:first_maps_project/widgets/models/map_info.dart';
import 'package:http/http.dart' as http;

/// Service for managing maps via REST API
class MapsApiService {
  final ApiClient _apiClient;

  MapsApiService({
    ApiClient? apiClient,
    http.Client? httpClient,
  }) : _apiClient = apiClient ?? ApiClient(httpClient: httpClient);

  /// Creates a new map
  Future<MapInfo> createMap(MapInfo map) async {
    final response = await _apiClient.post<MapInfo>(
      endpoint: ApiEndpoints.maps,
      body: map.toJson(),
      fromJson: MapInfo.fromJson,
    );

    return response.fold(
      onSuccess: (createdMap) => createdMap,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches all maps
  Future<List<MapInfo>> fetchMaps() async {
    final response = await _apiClient.getList<MapInfo>(
      endpoint: ApiEndpoints.maps,
      fromJson: MapInfo.fromJson,
    );

    return response.fold(
      onSuccess: (maps) => maps,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches a single map by ID
  Future<MapInfo?> fetchMapById(String mapId) async {
    final response = await _apiClient.get<MapInfo>(
      endpoint: ApiEndpoints.mapById(mapId),
      fromJson: MapInfo.fromJson,
    );

    return response.fold(
      onSuccess: (map) => map,
      onFailure: (error) {
        // Return null if map not found (404)
        if (error.statusCode == 404) {
          return null;
        }
        throw Exception(error.message);
      },
    );
  }

  /// Updates an existing map
  Future<MapInfo> updateMap(MapInfo map) async {
    if (map.id == null) {
      throw ArgumentError('Cannot update a map without an ID');
    }

    final response = await _apiClient.put<MapInfo>(
      endpoint: ApiEndpoints.mapById(map.id!),
      body: map.toJson(),
      fromJson: MapInfo.fromJson,
    );

    return response.fold(
      onSuccess: (updatedMap) => updatedMap,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Deletes a map by ID
  Future<void> deleteMap(String mapId) async {
    final response = await _apiClient.delete(
      endpoint: ApiEndpoints.mapById(mapId),
    );

    response.fold(
      onSuccess: (_) {},
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Checks if a map exists
  Future<bool> mapExists(String mapId) async {
    try {
      final map = await fetchMapById(mapId);
      return map != null;
    } catch (_) {
      return false;
    }
  }

  /// Fetches maps by owner
  Future<List<MapInfo>> fetchMapsByOwner(String owner) async {
    final response = await _apiClient.getList<MapInfo>(
      endpoint: ApiEndpoints.maps,
      queryParams: {'owner': owner},
      fromJson: MapInfo.fromJson,
    );

    return response.fold(
      onSuccess: (maps) => maps,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
} 