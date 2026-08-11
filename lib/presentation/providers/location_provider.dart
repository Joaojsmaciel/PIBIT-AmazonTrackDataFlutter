import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:amazon_track_data/core/services/background_tracking_service.dart';
import 'package:amazon_track_data/core/services/notification_service.dart';
import 'package:amazon_track_data/core/constants/app_constants.dart';
import 'package:amazon_track_data/data/models/active_tracking_session.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/trip_start_params.dart';
import 'auth_provider.dart';
import 'geofence_provider.dart';
import 'service_provider.dart';

// ---------------------------------------------------------------------------
// Localização atual do usuário (consulta pontual)
// ---------------------------------------------------------------------------

final userLocationProvider = FutureProvider<LatLng?>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final location = await locationRepo.getCurrentLocation();
  if (location == null) return null;
  return LatLng(location.latitude, location.longitude);
});

// ---------------------------------------------------------------------------
// Posição ao vivo durante rastreamento (alimentada pelo background service)
// ---------------------------------------------------------------------------

/// Última posição GPS conhecida durante o rastreamento ativo.
final liveLocationProvider = StateProvider<LatLng?>((ref) => null);

// ---------------------------------------------------------------------------
// Trilha de pontos GPS da viagem atual (ponto a ponto)
// ---------------------------------------------------------------------------

/// Lista ordenada de pontos GPS coletados na viagem em curso.
/// Resetada ao iniciar ou parar o rastreamento.
final liveTrailProvider = StateProvider<List<LatLng>>((ref) => const []);

/// Acrescenta [lat, lon] ao [liveTrailProvider] ignorando duplicatas próximas
/// (diferença < ~5 m) para evitar pontos redundantes quando foreground e
/// background service emitem dados quase simultaneamente.
void _addToTrail(Ref ref, double lat, double lon) {
  final current = ref.read(liveTrailProvider);
  final newPt = LatLng(lat, lon);
  if (current.isNotEmpty) {
    final last = current.last;
    if ((last.latitude - newPt.latitude).abs() < 0.00005 &&
        (last.longitude - newPt.longitude).abs() < 0.00005) {
      return;
    }
  }
  ref.read(liveTrailProvider.notifier).state = [...current, newPt];
}

// ---------------------------------------------------------------------------
// Usuários rastreados no mapa — via coleção livePositions (sem collectionGroup)
// ---------------------------------------------------------------------------

/// Stream de barqueiros com rastreamento ativo.
/// Usa a coleção plana [livePositions] — sem índice composto, sem colletionGroup.
/// O próprio usuário é filtrado; apenas entradas com tripId preenchido aparecem.
final trackedUsersProvider = StreamProvider<List<TrackedUserModel>>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final authRepo = ref.read(authRepositoryProvider);
  final currentUserId = authRepo.getCurrentUserId();

  return locationRepo
      .getLivePositionsStream()
      .map((users) {
        final cutoff = DateTime.now().millisecondsSinceEpoch -
            Duration(seconds: AppConstants.recentLocationWindowSeconds)
                .inMilliseconds;
        return users
            .where((u) => u.userId != currentUserId)
            .where((u) => u.tripId.isNotEmpty)
            .where((u) => u.timestamp >= cutoff)
            .toList();
      });
});

// ---------------------------------------------------------------------------
// Trilha ao vivo da embarcação acompanhada (passageiro)
// ---------------------------------------------------------------------------

/// Stream da trilha GPS da embarcação que o passageiro está acompanhando.
/// Retorna lista de [LatLng] ordenada por timestamp — atualizada em tempo real
/// conforme o barco salva pontos no Firestore.
final watchedBoatTrailProvider = StreamProvider<List<LatLng>>((ref) {
  final watchedBoatId = ref.watch(watchedBoatIdProvider);
  if (watchedBoatId == null) return Stream.value(const []);

  final trackedUsersAsync = ref.watch(trackedUsersProvider);
  return trackedUsersAsync.when(
    data: (users) {
      TrackedUserModel? boat;
      for (final u in users) {
        if (u.boatId == watchedBoatId) {
          boat = u;
          break;
        }
      }
      if (boat == null || boat.tripId.isEmpty) return Stream.value(const []);

      final locationRepo = ref.read(locationRepositoryProvider);
      return locationRepo
          .getTripPointsStream(boat.userId, boat.tripId)
          .map((pts) => pts.map((p) => LatLng(p.latitude, p.longitude)).toList());
    },
    loading: () => Stream.value(const []),
    error: (_, __) => Stream.value(const []),
  );
});

// ---------------------------------------------------------------------------
// Estado do rastreamento
// ---------------------------------------------------------------------------

final isTrackingProvider = StateProvider<bool>((ref) => false);
final currentTripIdProvider = StateProvider<String?>((ref) => null);
final selectedBoatForTrackingProvider = StateProvider<String?>((ref) => null);

/// Restaura o estado visual da viagem quando o processo principal do app é
/// recriado. O serviço Android continua sendo a fonte de coleta em background.
final restoreActiveTrackingProvider =
    FutureProvider<ActiveTrackingSession?>((ref) async {
  final session = await BackgroundTrackingService.restoreActiveSession();
  if (session != null) {
    ref.read(selectedBoatForTrackingProvider.notifier).state = session.boatId;
    ref.read(currentTripIdProvider.notifier).state = session.tripId;
    ref.read(isTrackingProvider.notifier).state = true;
  }
  return session;
});

/// Reata a interface ao stream do ForegroundService após uma reabertura.
/// Assim o mapa e o geofence voltam a receber posições sem iniciar outra trip.
final backgroundLocationBridgeProvider =
    StreamProvider<Map<String, dynamic>>((ref) async* {
  await for (final data in BackgroundTrackingService.locationStream) {
    if (data == null || !ref.read(isTrackingProvider)) continue;

    final lat = (data['latitude'] as num).toDouble();
    final lon = (data['longitude'] as num).toDouble();
    final smoothedSpeed = (data['smoothedSpeed'] as num).toDouble();

    ref.read(liveLocationProvider.notifier).state = LatLng(lat, lon);
    _addToTrail(ref, lat, lon);
    ref
        .read(geofenceServiceProvider)
        .updatePosition(lat, lon, smoothedSpeed);

    yield data;
  }
});

// ---------------------------------------------------------------------------
// Inicia rastreamento
// ---------------------------------------------------------------------------

/// Inicia o rastreamento GPS com Store-Carry-and-Forward (DTN).
///
/// O [BackgroundTrackingService] é a fonte única de GPS para evitar pontos
/// duplicados. Ele continua ativo com a tela apagada, salva no SQLite e
/// sincroniza com o Firestore quando há internet.
final startTrackingProvider =
    FutureProvider.family<void, TripStartParams>((ref, params) async {
  final boatId = params.boatId;
  final tripId = const Uuid().v4();

  await Future(() {
    ref.read(selectedBoatForTrackingProvider.notifier).state = boatId;
    ref.read(isTrackingProvider.notifier).state = true;
    ref.read(currentTripIdProvider.notifier).state = tripId;
  });

  final locationRepo = ref.read(locationRepositoryProvider);
  final authRepo = ref.read(authRepositoryProvider);

  final userId = authRepo.getCurrentUserId();

  var user = ref.read(userSessionProvider);
  if (user == null) {
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: attempt * 2));
      try {
        user = await authRepo.getCurrentUser();
        if (user != null) {
          ref.read(userSessionProvider.notifier).state = user;
          break;
        }
      } catch (_) {}
    }
  }

  if (userId == null || user == null) {
    await Future(() {
      ref.read(isTrackingProvider.notifier).state = false;
      ref.read(currentTripIdProvider.notifier).state = null;
      ref.read(selectedBoatForTrackingProvider.notifier).state = null;
    });
    throw StateError('Usuário não identificado. Entre novamente e tente.');
  }

  debugPrint(
      '[tracking] userId=$userId user=${user.fullName} boatId=$boatId tripId=$tripId');

  // Salva metadados da viagem (não depende de internet graças ao offline-first)
  try {
    await locationRepo.saveTripMeta(
      tripId: tripId,
      userId: userId,
      boatId: boatId,
      departurePoint: params.departurePoint,
      arrivalPoint: params.arrivalPoint,
      stops: params.stops,
      estimatedDurationMinutes: params.estimatedDurationMinutes,
      originLatitude: params.originLatitude,
      originLongitude: params.originLongitude,
      destinationLatitude: params.destinationLatitude,
      destinationLongitude: params.destinationLongitude,
    );
  } catch (e) {
    debugPrint('[tracking] aviso: falha ao salvar metadados: $e');
  }

  // ── Notificação persistente: aparece imediatamente na barra de status ─────
  final notifService = NotificationService();
  await notifService.showPersistentTracking(
    title: 'Amazon Track Data — Rastreamento ativo',
    body: 'Coletando localização GPS…',
  );

  // ── Inicia o ForegroundService (background GPS + DTN sync) ────────────────
  try {
    await BackgroundTrackingService.startTracking(
      userId: userId,
      tripId: tripId,
      boatId: boatId,
      userName: user.fullName,
      userType: user.userType.name,
      departurePoint: params.departurePoint,
      arrivalPoint: params.arrivalPoint,
      stops: params.stops,
    );
  } catch (e) {
    await notifService.cancelPersistentTracking();
    ref.read(isTrackingProvider.notifier).state = false;
    ref.read(currentTripIdProvider.notifier).state = null;
    ref.read(selectedBoatForTrackingProvider.notifier).state = null;
    throw StateError(
      'Não foi possível iniciar a coleta em segundo plano: $e',
    );
  }
});

// ---------------------------------------------------------------------------
// Para rastreamento
// ---------------------------------------------------------------------------

final stopTrackingWithResetProvider = FutureProvider.autoDispose<void>((ref) async {
  await BackgroundTrackingService.stopTracking();
  await NotificationService().cancelPersistentTracking();
  ref.read(geofenceServiceProvider).resetStatus();
  ref.read(isTrackingProvider.notifier).state = false;
  ref.read(currentTripIdProvider.notifier).state = null;
  ref.read(selectedBoatForTrackingProvider.notifier).state = null;
  ref.read(liveLocationProvider.notifier).state = null;
  ref.read(liveTrailProvider.notifier).state = const [];
  // Marca posição ao vivo como inativa no Firestore
  final userId = ref.read(authRepositoryProvider).getCurrentUserId();
  if (userId != null) {
    await ref.read(locationRepositoryProvider).setLivePositionInactive(userId);
  }
});

final stopTrackingProvider = FutureProvider.autoDispose<void>((ref) async {
  await BackgroundTrackingService.stopTracking();
  await NotificationService().cancelPersistentTracking();
  ref.read(isTrackingProvider.notifier).state = false;
  ref.read(currentTripIdProvider.notifier).state = null;
  ref.read(selectedBoatForTrackingProvider.notifier).state = null;
  ref.read(liveLocationProvider.notifier).state = null;
  ref.read(liveTrailProvider.notifier).state = const [];
  // Marca posição ao vivo como inativa no Firestore
  final userId = ref.read(authRepositoryProvider).getCurrentUserId();
  if (userId != null) {
    await ref.read(locationRepositoryProvider).setLivePositionInactive(userId);
  }
});

// ---------------------------------------------------------------------------
// Sincronização e limpeza
// ---------------------------------------------------------------------------

final syncOfflineLocationsProvider = FutureProvider<void>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  return await locationRepo.syncOfflineLocations();
});

final clearOldLocationsProvider = FutureProvider<void>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider);
  return await locationRepo.clearOldLocations(const Duration(days: 7));
});
