import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/trip_start_params.dart';
import 'package:amazon_track_data/core/constants/app_constants.dart';
import 'auth_provider.dart';
import 'service_provider.dart';

// Provider para obter a localização atual do usuário
final userLocationProvider = FutureProvider<LatLng?>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final location = await locationRepo.getCurrentLocation();
  if (location == null) return null;
  return LatLng(location.latitude, location.longitude);
});

final trackedUsersProvider = StreamProvider<List<TrackedUserModel>>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final authRepo = ref.read(authRepositoryProvider);
  final currentUserId = authRepo.getCurrentUserId();

  return locationRepo
      .getRecentTrackedUsers(
        windowDuration: Duration(
          seconds: AppConstants.recentLocationWindowSeconds,
        ),
      )
      .map((users) => users
          .where((u) => u.userId != currentUserId) // exclui o próprio usuário
          .where((u) => u.tripId.isNotEmpty)        // só quem está em trip ativa
          .toList());
});

// Providers para controlar o rastreamento
final isTrackingProvider = StateProvider<bool>((ref) => false);

final currentTripIdProvider = StateProvider<String?>((ref) => null);

final selectedBoatForTrackingProvider = StateProvider<String?>((ref) => null);

// Provider para iniciar rastreamento com intervalo de 5 segundos
final startTrackingProvider =
    FutureProvider.family<void, TripStartParams>((ref, params) async {
  final boatId = params.boatId;
  // Gera o tripId antes de deferir para usá-lo no restante da função
  final tripId = const Uuid().v4();

  // Adia as mutações de estado para evitar modificar providers durante a
  // fase de inicialização (erro de asserção do Riverpod)
  await Future(() {
    ref.read(selectedBoatForTrackingProvider.notifier).state = boatId;
    ref.read(isTrackingProvider.notifier).state = true;
    ref.read(currentTripIdProvider.notifier).state = tripId;
  });

  // ref.read (não ref.watch) após await — obrigatório em providers assíncronos
  final locationRepo = ref.read(locationRepositoryProvider);
  final authRepo = ref.read(authRepositoryProvider);

  final userId = authRepo.getCurrentUserId();

  // Tenta usar o cache em memória primeiro (zero chamadas ao Firestore)
  var user = ref.read(userSessionProvider);

  // Se o cache estiver vazio (ex: app reiniciado sem passar pelo login),
  // tenta buscar diretamente do repositório com até 3 tentativas e backoff
  if (user == null) {
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: attempt * 2));
      try {
        user = await authRepo.getCurrentUser();
        if (user != null) {
          ref.read(userSessionProvider.notifier).state = user;
          break;
        }
      } catch (_) {
        // erro transitório - tenta novamente
      }
    }
  }

  if (userId == null || user == null) {
    // Reverte o estado — não há usuário válido para rastrear
    await Future(() {
      ref.read(isTrackingProvider.notifier).state = false;
      ref.read(currentTripIdProvider.notifier).state = null;
      ref.read(selectedBoatForTrackingProvider.notifier).state = null;
    });
    return;
  }

  debugPrint('[tracking] userId=$userId user=${user.fullName} boatId=$boatId tripId=$tripId');

  // Salva os metadados da viagem (partida, paradas, chegada) no Firestore
  try {
    await locationRepo.saveTripMeta(
      tripId: tripId,
      userId: userId,
      boatId: boatId,
      departurePoint: params.departurePoint,
      arrivalPoint: params.arrivalPoint,
      stops: params.stops,
    );
  } catch (e) {
    debugPrint('[tracking] aviso: falha ao salvar metadados: $e');
    // não aborta o rastreamento se os metadados falharem
  }

  try {
    // Stream de posições a cada 5 segundos
    await for (final position in locationRepo.getPositionStream(intervalSeconds: 5)) {
      if (!ref.read(isTrackingProvider)) break;

      // Atualizar dados da localização com informações do usuário
      final location = LocationModel(
        userId: userId,
        tripId: tripId,
        boatId: boatId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        altitude: position.altitude,
        bearing: position.bearing,
        timestamp: position.timestamp,
        userType: user.userType.name,
        userName: user.fullName,
      );

      await locationRepo.saveLocation(location);
    }
  } catch (e) {
    ref.read(isTrackingProvider.notifier).state = false;
    rethrow;
  }
});

final stopTrackingProvider = FutureProvider<void>((ref) async {
  ref.read(isTrackingProvider.notifier).state = false;
  ref.read(currentTripIdProvider.notifier).state = null;
  ref.read(selectedBoatForTrackingProvider.notifier).state = null;
});

final syncOfflineLocationsProvider = FutureProvider<void>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  return await locationRepo.syncOfflineLocations();
});

final clearOldLocationsProvider = FutureProvider<void>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  return await locationRepo.clearOldLocations(
    const Duration(days: 7),
  );
});
