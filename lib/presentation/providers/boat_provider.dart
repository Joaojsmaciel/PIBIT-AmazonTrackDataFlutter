import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
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

  const ActiveTripInfo({
    required this.captainName,
    required this.departurePoint,
    required this.arrivalPoint,
    required this.stops,
    required this.speedMs,
  });

  String get speedKmh => (speedMs * 3.6).toStringAsFixed(1);
}

/// Mapa de boatId → ActiveTripInfo para todos os barcos com trip ativa agora.
final activeBoatTripsProvider =
    FutureProvider<Map<String, ActiveTripInfo>>((ref) async {
  final trackedUsers = await ref.watch(trackedUsersProvider.future);
  final locationRepo = ref.read(locationRepositoryProvider);
  final result = <String, ActiveTripInfo>{};

  for (final user in trackedUsers) {
    if (user.boatId.isEmpty || user.tripId.isEmpty) continue;
    try {
      final meta = await locationRepo.getTripMetaForUser(user.userId);
      final tripData = meta[user.tripId];
      result[user.boatId] = ActiveTripInfo(
        captainName: user.userName,
        departurePoint: tripData?['departurePoint'] as String? ?? '',
        arrivalPoint: tripData?['arrivalPoint'] as String? ?? '',
        stops: List<String>.from(tripData?['stops'] as List? ?? []),
        speedMs: user.speed,
      );
    } catch (_) {
      result[user.boatId] = ActiveTripInfo(
        captainName: user.userName,
        departurePoint: '',
        arrivalPoint: '',
        stops: [],
        speedMs: user.speed,
      );
    }
  }

  return result;
});
