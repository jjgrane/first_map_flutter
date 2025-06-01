import 'package:first_maps_project/services/api/api_client.dart';
import 'package:first_maps_project/services/api/api_endpoints.dart';
import 'package:first_maps_project/services/api/api_response.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:http/http.dart' as http;

/// Service for managing markers via REST API
class MarkersApiService {
  final ApiClient _apiClient;

  MarkersApiService({
    ApiClient? apiClient,
    http.Client? httpClient,
  }) : _apiClient = apiClient ?? ApiClient(httpClient: httpClient);

  /// Creates a new marker
  Future<MapMarker> createMarker(MapMarker marker) async {
    final response = await _apiClient.post<MapMarker>(
      endpoint: ApiEndpoints.markers,
      body: marker.toJson(),
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (createdMarker) => createdMarker,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches all markers
  Future<List<MapMarker>> fetchMarkers() async {
    final response = await _apiClient.getList<MapMarker>(
      endpoint: ApiEndpoints.markers,
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (markers) => markers,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches markers for a specific map
  Future<List<MapMarker>> fetchMarkersByMapId(String mapId) async {
    final response = await _apiClient.getList<MapMarker>(
      endpoint: ApiEndpoints.markers,
      queryParams: {'map_id': mapId},
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (markers) => markers,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches a single marker by ID
  Future<MapMarker?> fetchMarkerById(String markerId) async {
    final response = await _apiClient.get<MapMarker>(
      endpoint: ApiEndpoints.markerById(markerId),
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (marker) => marker,
      onFailure: (error) {
        // Return null if marker not found (404)
        if (error.statusCode == 404) {
          return null;
        }
        throw Exception(error.message);
      },
    );
  }

  /// Updates an existing marker
  Future<MapMarker> updateMarker(MapMarker marker) async {
    if (marker.markerId == null) {
      throw ArgumentError('Cannot update a marker without an ID');
    }

    final response = await _apiClient.put<MapMarker>(
      endpoint: ApiEndpoints.markerById(marker.markerId!),
      body: marker.toJson(),
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (updatedMarker) => updatedMarker,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Deletes a marker by ID
  Future<void> deleteMarker(String markerId) async {
    final response = await _apiClient.delete(
      endpoint: ApiEndpoints.markerById(markerId),
    );

    response.fold(
      onSuccess: (_) {},
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Updates a marker's group assignment
  Future<void> updateMarkerGroup(String markerId, String? groupId) async {
    final response = await _apiClient.put<MapMarker>(
      endpoint: ApiEndpoints.markerById(markerId),
      body: {'group_id': groupId},
      fromJson: MapMarker.fromJson,
    );

    response.fold(
      onSuccess: (_) {},
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Fetches markers by group ID
  Future<List<MapMarker>> fetchMarkersByGroupId(String groupId) async {
    final response = await _apiClient.getList<MapMarker>(
      endpoint: ApiEndpoints.markers,
      queryParams: {'group_id': groupId},
      fromJson: MapMarker.fromJson,
    );

    return response.fold(
      onSuccess: (markers) => markers,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Checks if a marker exists
  Future<bool> markerExists(String markerId) async {
    try {
      final marker = await fetchMarkerById(markerId);
      return marker != null;
    } catch (_) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
} 