import 'package:latlong2/latlong.dart';
import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/datasources/geolocator_datasource.dart';
import 'package:amazon_track_data/data/datasources/local_database.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';

class LocationRepository {
  final FirestoreDatasource _firestoreDatasource;
  final GeolocatorDatasource _geolocatorDatasource;
  final LocalDatabaseService _localDatabaseService;

  LocationRepository({
    required FirestoreDatasource firestoreDatasource,
    required GeolocatorDatasource geolocatorDatasource,
    required LocalDatabaseService localDatabaseService,
  })  : _firestoreDatasource = firestoreDatasource,
        _geolocatorDatasource = geolocatorDatasource,
        _localDatabaseService = localDatabaseService;

  Future<void> saveLocation(LocationModel location) async {
    try {
      await _firestoreDatasource.saveLocation(location);
      await _localDatabaseService.insertLocation(location);
    } catch (e) {
      // Se falhar online, salva offline para sincronização posterior
      await _localDatabaseService.insertLocation(location);
    }
  }

  Stream<List<TrackedUserModel>> getRecentTrackedUsers({
    Duration windowDuration = const Duration(seconds: 60),
  }) {
    try {
      return _firestoreDatasource
          .getRecentTrackedUsers(windowDuration)
          .map((locations) {
        final trackedUsers = <String, LocationModel>{};
        for (var location in locations) {
          trackedUsers[location.userId] = location;
        }
        return trackedUsers.values
            .map((loc) => TrackedUserModel(
                  userId: loc.userId,
                  userName: loc.userName,
                  userType: loc.userType,
                  latitude: loc.latitude,
                  longitude: loc.longitude,
                  speed: loc.speed,
                  accuracy: loc.accuracy,
                  timestamp: loc.timestamp,
                  tripId: loc.tripId,
                  boatId: loc.boatId,
                ))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncOfflineLocations() async {
    try {
      final unsynced = await _localDatabaseService.getAllUnsynced();
      for (int i = 0; i < unsynced.length; i++) {
        try {
          final location = LocationModel.fromMap(unsynced[i]);
          await _firestoreDatasource.saveLocation(location);
          await _localDatabaseService.markAsSynced(i);
        } catch (e) {
          // Continua com próximas localizações
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearOldLocations(Duration olderThan) async {
    try {
      final cutoff = DateTime.now().millisecondsSinceEpoch - olderThan.inMilliseconds;
      await _localDatabaseService.deleteOlderThan(cutoff);
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      return await _geolocatorDatasource.getCurrentLocation();
    } catch (e) {
      rethrow;
    }
  }

  Stream<LocationModel> getPositionStream({int intervalSeconds = 5}) {
    try {
      return _geolocatorDatasource
          .getPositionStream(intervalSeconds: intervalSeconds)
          .map((position) => LocationModel(
            userId: '',
            userName: '',
            userType: '',
            latitude: position.latitude,
            longitude: position.longitude,
            speed: position.speed,
            accuracy: position.accuracy,
            altitude: position.altitude,
            bearing: position.heading,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            tripId: '',
          ));
    } catch (e) {
      rethrow;
    }
  }

  /// Retorna o histórico de viagens de um usuário agrupado por tripId.
  /// Cada viagem inclui stats calculadas: duração, velocidade média, distância.
  Future<List<TripSummary>> getUserTrips(String userId) async {
    final locations = await _firestoreDatasource.getAllUserLocations(userId);

    // Busca metadados (partida/paradas/chegada) em paralelo
    Map<String, Map<String, dynamic>> metaMap = {};
    try {
      metaMap = await _firestoreDatasource.getTripMetaForUser(userId);
    } catch (_) {
      // não bloqueia se falhar — meta é opcional
    }

    // Agrupa por tripId
    final grouped = <String, List<LocationModel>>{};
    for (final loc in locations) {
      if (loc.tripId.isEmpty) continue;
      grouped.putIfAbsent(loc.tripId, () => []).add(loc);
    }

    final distCalc = const Distance();
    final trips = <TripSummary>[];

    for (final entry in grouped.entries) {
      final points = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (points.isEmpty) continue;

      final first = points.first;
      final last = points.last;
      final meta = metaMap[entry.key];

      // Velocidade média (m/s)
      final avgSpeedMs = points.isEmpty
          ? 0.0
          : points.map((p) => p.speed).reduce((a, b) => a + b) / points.length;

      // Distância total em metros
      double totalDistance = 0;
      for (int i = 1; i < points.length; i++) {
        totalDistance += distCalc(
          LatLng(points[i - 1].latitude, points[i - 1].longitude),
          LatLng(points[i].latitude, points[i].longitude),
        );
      }

      trips.add(TripSummary(
        tripId: entry.key,
        userId: userId,
        userName: first.userName,
        boatId: first.boatId,
        startTimestamp: first.timestamp,
        endTimestamp: last.timestamp,
        startLat: first.latitude,
        startLng: first.longitude,
        endLat: last.latitude,
        endLng: last.longitude,
        pointCount: points.length,
        avgSpeedMs: avgSpeedMs,
        totalDistanceMeters: totalDistance,
        departurePoint: meta?['departurePoint'] as String? ?? '',
        arrivalPoint: meta?['arrivalPoint'] as String? ?? '',
        stops: (meta?['stops'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ));
    }

    // Mais recentes primeiro
    trips.sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));
    return trips;
  }

  /// Salva os metadados da viagem (pontos de rota) no Firestore.
  Future<void> saveTripMeta({
    required String tripId,
    required String userId,
    required String boatId,
    required String departurePoint,
    required String arrivalPoint,
    required List<String> stops,
  }) async {
    await _firestoreDatasource.saveTripMeta(
      tripId: tripId,
      userId: userId,
      boatId: boatId,
      departurePoint: departurePoint,
      arrivalPoint: arrivalPoint,
      stops: stops,
    );
  }

  /// Retorna os pontos GPS de uma trip específica, ordenados por timestamp.
  Future<List<LocationModel>> getTripPoints(String userId, String tripId) async {
    return await _firestoreDatasource.getUserTripPoints(userId, tripId);
  }

  /// Retorna todos os metadados de viagens de um usuário, indexados por tripId.
  Future<Map<String, Map<String, dynamic>>> getTripMetaForUser(String userId) async {
    return await _firestoreDatasource.getTripMetaForUser(userId);
  }
}
