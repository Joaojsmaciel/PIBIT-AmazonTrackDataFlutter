class AppConstants {
  // Intervalos de rastreamento
  static const int locationUpdateIntervalSeconds = 5;
  static const int backgroundLocationUpdateIntervalSeconds = 10;
  static const int recentLocationWindowSeconds = 120;
  
  // Limites e validações
  static const int minPasswordLength = 6;
  static const int cpfLength = 11;
  static const int minNameWords = 2;
  static const double geofenceRadiusMeters = 500;
  
  // Chaves de armazenamento local
  static const String userPreferencesKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String lastLocationKey = 'last_location';
  static const String userTypeKey = 'user_type';
  static const String currentTripKey = 'current_trip';
  
  // URLs e endpoints
  static const String openStreetMapTile = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapboxAttribution = '© OpenStreetMap contributors';
  
  // Margens e padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Raios de borda
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
}
