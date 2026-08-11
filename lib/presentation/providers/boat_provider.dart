import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'service_provider.dart';
import 'auth_provider.dart';
import 'location_provider.dart';

final userBoatsProvider = FutureProvider<List<BoatModel>>((ref) async {
  // currentUserIdProvider lê FirebaseAuth.currentUser?.uid de forma síncrona.
  // Quando o usuário chega nesta tela já está autenticado (splash garante isso).
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final boatRepo = ref.watch(boatRepositoryProvider);
  return await boatRepo.getUserBoats(userId);
});

final createBoatProvider = FutureProvider.family<void, ({
  BoatModel boat,
  File? imageFile,
})>((ref, params) async {
  final boatRepo = ref.watch(boatRepositoryProvider);
  await boatRepo.createBoat(params.boat, imageFile: params.imageFile);
  // Invalida o cache para refresh
  ref.invalidate(userBoatsProvider);
});

final updateBoatProvider = FutureProvider.family<void, ({
  BoatModel boat,
  File? imageFile,
})>((ref, params) async {
  final boatRepo = ref.watch(boatRepositoryProvider);
  await boatRepo.updateBoat(params.boat, imageFile: params.imageFile);
  ref.invalidate(userBoatsProvider);
});

final deleteBoatProvider = FutureProvider.family<void, String>((ref, boatId) async {
  final boatRepo = ref.watch(boatRepositoryProvider);
  await boatRepo.deleteBoat(boatId);
  ref.invalidate(userBoatsProvider);
});

final selectedBoatProvider = StateProvider<BoatModel?>((ref) => null);

final allBoatsProvider = FutureProvider<List<BoatModel>>((ref) async {
  final boatRepo = ref.watch(boatRepositoryProvider);
  return await boatRepo.getAllBoats();
});

/// Informações de uma viagem ativa vinculada a um barco.
class ActiveTripInfo {
  final String captainName;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;
  final double speedMs;
  final double currentLatitude;
  final double currentLongitude;
  final int currentTimestamp;
  final int startTimestamp;
  final int estimatedDurationMinutes;
  final double? destinationLatitude;
  final double? destinationLongitude;

  const ActiveTripInfo({
    required this.captainName,
    required this.departurePoint,
    required this.arrivalPoint,
    required this.stops,
    required this.speedMs,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentTimestamp,
    this.startTimestamp = 0,
    this.estimatedDurationMinutes = 0,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  String get speedKmh =>
      ((speedMs < 0 ? 0 : speedMs) * 3.6).toStringAsFixed(1);

  bool get hasDestinationCoordinates {
    final lat = destinationLatitude;
    final lng = destinationLongitude;
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        (lat != 0 || lng != 0);
  }

  double? get distanceRemainingMeters {
    if (!hasDestinationCoordinates) return null;
    return Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      destinationLatitude!,
      destinationLongitude!,
    );
  }

  Duration? get remainingDuration {
    final distance = distanceRemainingMeters;
    if (distance != null && speedMs >= 0.5) {
      final seconds = (distance / speedMs).round();
      return Duration(seconds: seconds.clamp(0, 2592000).toInt());
    }

    if (startTimestamp > 0 && estimatedDurationMinutes > 0) {
      final plannedArrival = DateTime.fromMillisecondsSinceEpoch(startTimestamp)
          .add(Duration(minutes: estimatedDurationMinutes));
      final remaining = plannedArrival.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return null;
  }

  DateTime? get estimatedArrival {
    if (distanceRemainingMeters != null && speedMs >= 0.5) {
      final remaining = remainingDuration;
      return remaining == null ? null : DateTime.now().add(remaining);
    }
    if (startTimestamp > 0 && estimatedDurationMinutes > 0) {
      return DateTime.fromMillisecondsSinceEpoch(startTimestamp)
          .add(Duration(minutes: estimatedDurationMinutes));
    }
    return null;
  }

  double? get progress {
    if (startTimestamp <= 0 || estimatedDurationMinutes <= 0) return null;
    final total = Duration(minutes: estimatedDurationMinutes).inMilliseconds;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimestamp;
    return (elapsed / total).clamp(0.0, 1.0).toDouble();
  }
}

final _activeTripMetaProvider = FutureProvider.family<
    Map<String, dynamic>?,
    ({String userId, String tripId})>((ref, params) async {
  final locationRepo = ref.read(locationRepositoryProvider);
  final allMeta = await locationRepo.getTripMetaForUser(params.userId);
  return allMeta[params.tripId];
});

final _routeCatalogProvider = FutureProvider<List<RouteModel>>((ref) {
  return ref.read(routeRepositoryProvider).getAllRoutes();
});

/// Mapa de boatId → ActiveTripInfo para todos os barcos com trip ativa agora.
final activeBoatTripsProvider =
    FutureProvider<Map<String, ActiveTripInfo>>((ref) async {
  final trackedUsers = ref.watch(trackedUsersProvider).valueOrNull ?? const [];
  var routeCatalog = const <RouteModel>[];
  if (trackedUsers.isNotEmpty) {
    try {
      routeCatalog = await ref.read(_routeCatalogProvider.future);
    } catch (_) {}
  }
  final result = <String, ActiveTripInfo>{};

  for (final user in trackedUsers) {
    if (user.boatId.isEmpty || user.tripId.isEmpty) continue;
    try {
      final tripData = await ref.read(_activeTripMetaProvider(
        (userId: user.userId, tripId: user.tripId),
      ).future);
      final departurePoint =
          tripData?['departurePoint'] as String? ?? '';
      final arrivalPoint = tripData?['arrivalPoint'] as String? ?? '';
      final matchedRoute = _matchRoute(
        routeCatalog,
        departurePoint,
        arrivalPoint,
      );
      result[user.boatId] = ActiveTripInfo(
        captainName: user.userName,
        departurePoint: departurePoint,
        arrivalPoint: arrivalPoint,
        stops: List<String>.from(tripData?['stops'] as List? ?? []),
        speedMs: user.speed,
        currentLatitude: user.latitude,
        currentLongitude: user.longitude,
        currentTimestamp: user.timestamp,
        startTimestamp:
            (tripData?['createdAt'] as num?)?.toInt() ?? 0,
        estimatedDurationMinutes:
            (tripData?['estimatedDurationMinutes'] as num?)?.toInt() ??
                matchedRoute?.estimatedDurationMinutes ??
                0,
        destinationLatitude:
            (tripData?['destinationLatitude'] as num?)?.toDouble() ??
                (_validCoordinate(matchedRoute?.destination.latitude)
                    ? matchedRoute!.destination.latitude
                    : null),
        destinationLongitude:
            (tripData?['destinationLongitude'] as num?)?.toDouble() ??
                (_validCoordinate(matchedRoute?.destination.longitude)
                    ? matchedRoute!.destination.longitude
                    : null),
      );
    } catch (_) {
      result[user.boatId] = ActiveTripInfo(
        captainName: user.userName,
        departurePoint: '',
        arrivalPoint: '',
        stops: [],
        speedMs: user.speed,
        currentLatitude: user.latitude,
        currentLongitude: user.longitude,
        currentTimestamp: user.timestamp,
      );
    }
  }

  return result;
});

RouteModel? _matchRoute(
  List<RouteModel> routes,
  String departurePoint,
  String arrivalPoint,
) {
  final departure = _normalizeRouteLabel(departurePoint);
  final arrival = _normalizeRouteLabel(arrivalPoint);
  for (final route in routes) {
    final origin = _normalizeRouteLabel(
      route.origin.name.isNotEmpty ? route.origin.name : route.origin.city,
    );
    final destination = _normalizeRouteLabel(
      route.destination.name.isNotEmpty
          ? route.destination.name
          : route.destination.city,
    );
    if (origin == departure && destination == arrival) return route;
  }
  return null;
}

String _normalizeRouteLabel(String value) => value.trim().toLowerCase();

bool _validCoordinate(double? value) =>
    value != null && value != 0 && value.isFinite;
