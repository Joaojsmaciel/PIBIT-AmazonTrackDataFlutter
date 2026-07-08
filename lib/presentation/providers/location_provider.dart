import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:amazon_track_data/core/services/background_tracking_service.dart';
import 'package:amazon_track_data/core/services/notification_service.dart';
import 'package:amazon_track_data/core/constants/app_constants.dart';
import 'package:amazon_track_data/core/utils/kalman_filter.dart';
import 'package:amazon_track_data/data/models/local_location_point.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
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

// ---------------------------------------------------------------------------
// Inicia rastreamento
// ---------------------------------------------------------------------------

/// Inicia o rastreamento GPS com Store-Carry-and-Forward (DTN).
///
/// Estratégia dupla:
///  1. **Foreground**: stream GPS direto no isolate principal → atualiza
///     geofence e mapa com velocidade suavizada pelo filtro de Kalman.
///  2. **Background**: [BackgroundTrackingService] (ForegroundService Android)
///     continua capturando GPS mesmo com a tela apagada, salva no SQLite e
///     sincroniza com o Firestore quando há internet.
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
  final offlineSyncService = ref.read(offlineSyncServiceProvider);

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
    return;
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
    );
  } catch (e) {
    debugPrint('[tracking] aviso: falha ao iniciar background service: $e');
  }

  // ── Escuta eventos do background service para atualizar geofence/mapa ─────
  StreamSubscription<Map<String, dynamic>?>? bgSub;
  bgSub = BackgroundTrackingService.locationStream.listen((data) {
    if (data == null) return;
    if (!ref.read(isTrackingProvider)) {
      bgSub?.cancel();
      return;
    }
    final lat = (data['latitude'] as num).toDouble();
    final lon = (data['longitude'] as num).toDouble();
    final smoothedSpeed = (data['smoothedSpeed'] as num).toDouble();

    // Atualiza posição ao vivo no mapa
    ref.read(liveLocationProvider.notifier).state = LatLng(lat, lon);

    // Acumula ponto na trilha ponto a ponto
    _addToTrail(ref, lat, lon);

    // Atualiza estado de geofencing com velocidade Kalman
    final geofenceService = ref.read(geofenceServiceProvider);
    geofenceService.updatePosition(lat, lon, smoothedSpeed);
  });

  ref.onDispose(() => bgSub?.cancel());

  // ── Foreground GPS: Kalman + SQLite + sync DTN ────────────────────────────
  // O background service é a fonte principal quando a tela apaga; este loop
  // complementa enquanto o app está em foreground e nunca deve terminar por
  // falhas de IO — cada iteração é isolada com try-catch.
  final kalman = KalmanFilter(initialValue: 0.0);

  await for (final position
      in locationRepo.getPositionStream(intervalSeconds: 5)) {
    if (!ref.read(isTrackingProvider)) break;

    final smoothedSpeed = kalman.update(position.speed);
    final speedKmh = (smoothedSpeed * 3.6).toStringAsFixed(1);

    final location = LocationModel(
      userId: userId,
      tripId: tripId,
      boatId: boatId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: smoothedSpeed,
      accuracy: position.accuracy,
      altitude: position.altitude,
      bearing: position.bearing,
      timestamp: position.timestamp,
      userType: user.userType.name,
      userName: user.fullName,
    );

    // ── STORE: SQLite + Firestore; falhas não encerram o loop ─────────────
    try {
      await locationRepo.saveLocation(location);
    } catch (e) {
      debugPrint('[tracking] aviso: falha ao salvar ponto (continuando): $e');
    }

    // ── CARRY: fila SharedPreferences (fallback de curto prazo) ──────────
    try {
      await offlineSyncService.savePoint(LocalLocationPoint(
        id: '${userId}_${location.timestamp}',
        userId: userId,
        tripId: tripId,
        boatId: boatId,
        latitude: position.latitude,
        longitude: position.longitude,
        velocidade: smoothedSpeed,
        timestamp: DateTime.fromMillisecondsSinceEpoch(position.timestamp),
      ));
    } catch (_) {}

    // ── FORWARD: sync SQLite → Firestore quando há conexão ───────────────
    try {
      final conn = await Connectivity().checkConnectivity();
      final online = conn == ConnectivityResult.mobile ||
          conn == ConnectivityResult.wifi ||
          conn == ConnectivityResult.ethernet;
      if (online) {
        await locationRepo.syncOfflineLocations();
      }
    } catch (_) {}

    // Geofence com velocidade Kalman
    final geofenceService = ref.read(geofenceServiceProvider);
    geofenceService.updatePosition(
      position.latitude,
      position.longitude,
      smoothedSpeed,
    );

    // Posição ao vivo + rastro ponto a ponto
    ref.read(liveLocationProvider.notifier).state =
        LatLng(position.latitude, position.longitude);
    _addToTrail(ref, position.latitude, position.longitude);

    // Notificação persistente com velocidade Kalman
    try {
      final geofenceEvent = geofenceService.getPortoMaisProximo(
        position.latitude,
        position.longitude,
        smoothedSpeed,
      );
      if (geofenceEvent != null) {
        await notifService.showPersistentTracking(
          title: 'Aproximando: ${geofenceEvent.porto.nome}',
          body: 'ETA ${geofenceEvent.etaFormatado} · $speedKmh km/h',
        );
      } else {
        await notifService.showPersistentTracking(
          title: 'Amazon Track Data — Rastreamento ativo',
          body: 'Velocidade: $speedKmh km/h · GPS coletando…',
        );
      }
    } catch (_) {}
  }
});

// ---------------------------------------------------------------------------
// Para rastreamento
// ---------------------------------------------------------------------------

final stopTrackingWithResetProvider = FutureProvider<void>((ref) async {
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

final stopTrackingProvider = FutureProvider<void>((ref) async {
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
