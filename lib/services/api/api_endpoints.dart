/// Centralized API endpoints configuration
class ApiEndpoints {
  // Base URL - can be configured per environment
  static const String baseUrl = 'http://192.168.0.107:8080';
  
  // Markers endpoints
  static const String markers = '/markers';
  static String markerById(String id) => '$markers/$id';
  
  // Maps endpoints  
  static const String maps = '/maps';
  static String mapById(String id) => '$maps/$id';
  
  // Places endpoints (for future use)
  static const String places = '/places';
  static String placeById(String id) => '$places/$id';
} 