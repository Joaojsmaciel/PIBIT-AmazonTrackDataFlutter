import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// flutter_background_service_android re-exports via flutter_background_service
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:amazon_track_data/core/constants/firestore_paths.dart';
import 'package:amazon_track_data/core/utils/kalman_filter.dart';
import 'package:amazon_track_data/data/models/active_tracking_session.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/port_model.dart';
import 'package:amazon_track_data/firebase_options.dart';

// ---------------------------------------------------------------------------
// Constantes públicas
// ---------------------------------------------------------------------------

/// Canal de notificação Android para o rastreamento em background.
const String kTrackingChannelId = 'amazon_tracking_channel';

/// ID da notificação persistente do ForegroundService.
const int kTrackingNotificationId = 888;

// ---------------------------------------------------------------------------
// Serviço de background — API pública
// ---------------------------------------------------------------------------

/// Gerencia o ForegroundService Android que captura GPS e sincroniza dados
/// mesmo quando o aplicativo está em background, seguindo o paradigma
/// Store-Carry-and-Forward das Redes DTN.
class BackgroundTrackingService {
  BackgroundTrackingService._();

  static final FlutterBackgroundService _svc = FlutterBackgroundService();

  /// Stream de eventos de localização emitidos pelo background isolate.
  ///
  /// Cada mapa contém:
  ///   `latitude`, `longitude`, `speed` (raw), `smoothedSpeed` (Kalman),
  ///   `timestamp` (ms epoch).
  static Stream<Map<String, dynamic>?> get locationStream =>
      _svc.on('location_update');

  /// Configura o serviço uma única vez (chamar em [main] antes do [runApp]).
  static Future<void> initialize() async {
    // Cria o canal de notificação no Android
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            kTrackingChannelId,
            'Rastreamento de Embarcação',
            description:
                'Notificação persistente enquanto o rastreamento GPS está ativo.',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );

    await _svc.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: kTrackingChannelId,
        initialNotificationTitle: 'Amazon Track Data',
        initialNotificationContent: 'Rastreamento GPS ativo',
        foregroundServiceNotificationId: kTrackingNotificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  // Chaves usadas no SharedPreferences para persistir os parâmetros da viagem.
  static const _kUserId   = 'bg_userId';
  static const _kTripId   = 'bg_tripId';
  static const _kBoatId   = 'bg_boatId';
  static const _kUserName = 'bg_userName';
  static const _kUserType = 'bg_userType';
  static const _kDeparturePoint = 'bg_departurePoint';
  static const _kArrivalPoint = 'bg_arrivalPoint';
  static const _kStops = 'bg_stops';
  static const _kActive   = 'bg_active';

  /// Inicia o serviço e persiste os parâmetros da viagem.
  ///
  /// Os parâmetros são gravados no SharedPreferences **antes** de `startService()`
  /// para que o background isolate possa lê-los ao inicializar, sem depender do
  /// timing do evento `start_tracking` (que pode chegar antes do listener estar
  /// pronto em dispositivos lentos).
  static Future<void> startTracking({
    required String userId,
    required String tripId,
    required String boatId,
    required String userName,
    required String userType,
    required String departurePoint,
    required String arrivalPoint,
    required List<String> stops,
  }) async {
    // Persiste parâmetros — lidos pelo isolate no _onStart
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId,   userId);
    await prefs.setString(_kTripId,   tripId);
    await prefs.setString(_kBoatId,   boatId);
    await prefs.setString(_kUserName, userName);
    await prefs.setString(_kUserType, userType);
    await prefs.setString(_kDeparturePoint, departurePoint);
    await prefs.setString(_kArrivalPoint, arrivalPoint);
    await prefs.setStringList(_kStops, stops);
    await prefs.setBool(_kActive, true);

    try {
      await _svc.startService();
    } catch (_) {
      await prefs.setBool(_kActive, false);
      rethrow;
    }

    // Envia evento também — redundante, mas garante compatibilidade
    await Future.delayed(const Duration(milliseconds: 1500));
    _svc.invoke('start_tracking', {
      'userId': userId,
      'tripId': tripId,
      'boatId': boatId,
      'userName': userName,
      'userType': userType,
    });
  }

  /// Restaura a viagem ativa após a interface ser recriada.
  ///
  /// O SharedPreferences é a fonte de verdade porque permanece disponível
  /// mesmo quando o processo do Flutter é removido dos aplicativos recentes.
  /// Se o Android matou o serviço, ele também é iniciado novamente com os
  /// parâmetros já persistidos.
  static Future<ActiveTrackingSession?> restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kActive) ?? false)) return null;

    final userId = prefs.getString(_kUserId) ?? '';
    final tripId = prefs.getString(_kTripId) ?? '';
    final boatId = prefs.getString(_kBoatId) ?? '';
    if (userId.isEmpty || tripId.isEmpty) {
      await prefs.setBool(_kActive, false);
      return null;
    }

    if (!await _svc.isRunning()) {
      await _svc.startService();
    }

    return ActiveTrackingSession(
      userId: userId,
      tripId: tripId,
      boatId: boatId,
      userName: prefs.getString(_kUserName) ?? '',
      userType: prefs.getString(_kUserType) ?? '',
      departurePoint: prefs.getString(_kDeparturePoint) ?? '',
      arrivalPoint: prefs.getString(_kArrivalPoint) ?? '',
      stops: prefs.getStringList(_kStops) ?? const [],
    );
  }

  /// Para o rastreamento, encerra o ForegroundService e limpa os parâmetros.
  static Future<void> stopTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActive, false);
    _svc.invoke('stop_tracking');
  }

  /// Retorna `true` se o serviço está em execução.
  static Future<bool> isRunning() => _svc.isRunning();
}

// ---------------------------------------------------------------------------
// Ponto de entrada do background isolate (iOS)
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ---------------------------------------------------------------------------
// Ponto de entrada do background isolate (Android + iOS foreground)
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // ── ForegroundService: notificação aparece imediatamente ─────────────────
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'Amazon Track Data',
      content: 'Rastreamento GPS ativo…',
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final Database db = await _openDatabase();

  String? userId, tripId, boatId, userName, userType;
  bool active = false;
  StreamSubscription<Position>? gpsSub;
  final KalmanFilter kalman = KalmanFilter(initialValue: 0.0);

  // ── Listener de conectividade: sync ao reconectar ────────────────────────
  Connectivity().onConnectivityChanged.listen((result) async {
    if (active && _isOnline(result) && userId != null) {
      await _syncPendingToFirestore(db, userId!);
    }
  });

  // ── Inicia (ou reinicia) o stream GPS com os parâmetros atuais ───────────
  void startGps() {
    if (active || userId == null) return;
    active = true;
    kalman.reset(initialValue: 0.0);
    debugPrint('[BG] GPS iniciado: user=$userId trip=$tripId');

    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: const Duration(seconds: 5),
        distanceFilter: 0,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationChannelName: 'Rastreamento de Embarcação',
          notificationText: 'Coletando localização GPS…',
          notificationTitle: 'Amazon Track Data',
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    gpsSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((pos) async {
      if (!active) return;

      final smoothedSpeed = kalman.update(pos.speed);
      final ts = pos.timestamp.millisecondsSinceEpoch;

      final location = LocationModel(
        userId: userId!,
        tripId: tripId!,
        boatId: boatId ?? '',
        latitude: pos.latitude,
        longitude: pos.longitude,
        speed: smoothedSpeed,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        bearing: pos.heading,
        timestamp: ts,
        userType: userType ?? '',
        userName: userName ?? '',
      );

      // STORE
      await _insertLocation(db, location);

      // FORWARD
      try {
        final conn = await Connectivity().checkConnectivity();
        if (_isOnline(conn)) {
          await _syncPendingToFirestore(db, userId!);
          await _updateLivePosition(location);
        }
      } catch (e) {
        debugPrint('[BG] Sync error: $e');
      }

      // Notificação persistente
      try {
        final n = _buildNotificationContent(
          lat: pos.latitude,
          lon: pos.longitude,
          smoothedSpeedMps: smoothedSpeed,
        );
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(title: n.title, content: n.body);
        }
      } catch (_) {}

      // Atualiza UI do app principal
      service.invoke('location_update', {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'speed': pos.speed,
        'smoothedSpeed': smoothedSpeed,
        'timestamp': ts,
      });
    });
  }

  // ── Lê parâmetros salvos no SharedPreferences (inicia sem depender de evento)
  try {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(BackgroundTrackingService._kActive) ?? false;
    if (isActive) {
      userId   = prefs.getString(BackgroundTrackingService._kUserId);
      tripId   = prefs.getString(BackgroundTrackingService._kTripId);
      boatId   = prefs.getString(BackgroundTrackingService._kBoatId);
      userName = prefs.getString(BackgroundTrackingService._kUserName);
      userType = prefs.getString(BackgroundTrackingService._kUserType);
      debugPrint('[BG] Parâmetros restaurados do SharedPreferences');
      startGps();
    }
  } catch (e) {
    debugPrint('[BG] Aviso: falha ao ler SharedPreferences: $e');
  }

  // ── Recebe parâmetros via evento (fallback / nova viagem) ─────────────────
  service.on('start_tracking').listen((data) async {
    if (data == null) return;
    userId   = data['userId'] as String?;
    tripId   = data['tripId'] as String?;
    boatId   = (data['boatId'] as String?) ?? '';
    userName = (data['userName'] as String?) ?? '';
    userType = (data['userType'] as String?) ?? '';
    if (!active) startGps();
  });

  // ── Para o rastreamento ───────────────────────────────────────────────────
  service.on('stop_tracking').listen((_) async {
    debugPrint('[BG] Parando rastreamento...');
    active = false;
    await gpsSub?.cancel();
    if (userId != null) {
      try { await _setLivePositionInactive(userId!); } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BackgroundTrackingService._kActive, false);
    } catch (_) {}
    await db.close();
    service.stopSelf();
  });
}

// ---------------------------------------------------------------------------
// Helpers do background isolate
// ---------------------------------------------------------------------------

Future<Database> _openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'amazon_track.db');

  return openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_points (
          id        TEXT    PRIMARY KEY,
          userId    TEXT    NOT NULL,
          tripId    TEXT    NOT NULL,
          boatId    TEXT    NOT NULL DEFAULT '',
          latitude  REAL    NOT NULL,
          longitude REAL    NOT NULL,
          speed     REAL    NOT NULL DEFAULT 0.0,
          accuracy  REAL    NOT NULL DEFAULT 0.0,
          altitude  REAL,
          bearing   REAL,
          userType  TEXT    NOT NULL DEFAULT '',
          userName  TEXT    NOT NULL DEFAULT '',
          timestamp INTEGER NOT NULL,
          synced    INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_synced_ts ON location_points (synced, timestamp)',
      );
    },
  );
}

Future<void> _insertLocation(Database db, LocationModel location) async {
  try {
    final id = '${location.userId}_${location.timestamp}';
    await db.insert(
      'location_points',
      {
        'id': id,
        ...location.toMap(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  } catch (e) {
    debugPrint('[BG] Erro ao inserir no SQLite: $e');
  }
}

/// Sincroniza até 50 pontos pendentes com o Firestore (DTN FORWARD).
Future<void> _syncPendingToFirestore(Database db, String userId) async {
  try {
    final rows = await db.query(
      'location_points',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
      limit: 50,
    );

    if (rows.isEmpty) return;

    debugPrint('[BG] Sincronizando ${rows.length} ponto(s)…');

    final firestore = FirebaseFirestore.instance;
    int synced = 0;

    for (final row in rows) {
      try {
        final id = row['id'] as String;
        final location = _locationFromRow(row);

        await firestore
            .collection(FirestorePaths.locationTracksPath(location.userId))
            .doc(location.timestamp.toString())
            .set(location.toMap(), SetOptions(merge: true));

        await db.update(
          'location_points',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
        synced++;
      } catch (e) {
        debugPrint('[BG] Falha ao sync ponto: $e');
      }
    }

    debugPrint('[BG] $synced/${rows.length} pontos sincronizados.');
  } catch (e) {
    debugPrint('[BG] Erro durante sync em lote: $e');
  }
}

LocationModel _locationFromRow(Map<String, dynamic> row) {
  return LocationModel(
    userId: (row['userId'] as String?) ?? '',
    tripId: (row['tripId'] as String?) ?? '',
    boatId: (row['boatId'] as String?) ?? '',
    latitude: (row['latitude'] as num).toDouble(),
    longitude: (row['longitude'] as num).toDouble(),
    speed: (row['speed'] as num?)?.toDouble() ?? 0.0,
    accuracy: (row['accuracy'] as num?)?.toDouble() ?? 0.0,
    altitude: (row['altitude'] as num?)?.toDouble(),
    bearing: (row['bearing'] as num?)?.toDouble(),
    timestamp: row['timestamp'] as int,
    userType: (row['userType'] as String?) ?? '',
    userName: (row['userName'] as String?) ?? '',
  );
}

bool _isOnline(ConnectivityResult result) {
  return result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;
}

/// Atualiza o documento de posição ao vivo no Firestore (coleção plana).
Future<void> _updateLivePosition(LocationModel location) async {
  await FirebaseFirestore.instance
      .collection(FirestorePaths.livePositionsCollection)
      .doc(location.userId)
      .set({
    ...location.toMap(),
    'active': true,
  }, SetOptions(merge: true));
}

/// Marca o documento de posição ao vivo como inativo.
Future<void> _setLivePositionInactive(String userId) async {
  await FirebaseFirestore.instance
      .collection(FirestorePaths.livePositionsCollection)
      .doc(userId)
      .set({'active': false}, SetOptions(merge: true));
}

// ---------------------------------------------------------------------------
// Conteúdo da notificação persistente
// ---------------------------------------------------------------------------

class _NotifContent {
  final String title;
  final String body;
  const _NotifContent(this.title, this.body);
}

/// Calcula título e corpo da notificação com ETA usando Kalman + Haversine
/// (via Geolocator.distanceBetween, que implementa a fórmula de Haversine).
_NotifContent _buildNotificationContent({
  required double lat,
  required double lon,
  required double smoothedSpeedMps,
}) {
  final speedKmh = smoothedSpeedMps * 3.6;
  final speedStr = '${speedKmh.toStringAsFixed(1)} km/h';

  // Verifica qual porto está na zona de aproximação
  PortModel? nearest;
  double nearestDist = double.infinity;

  for (final porto in AmazonPorts.all) {
    final dist = Geolocator.distanceBetween(
      lat, lon, porto.latitude, porto.longitude,
    );
    if (dist < porto.raioAproximacao && dist < nearestDist) {
      nearestDist = dist;
      nearest = porto;
    }
  }

  if (nearest != null) {
    // ETA com velocidade suavizada pelo filtro de Kalman (limiar 0,5 m/s)
    final etaStr = smoothedSpeedMps >= 0.5
        ? _formatEta(nearestDist / smoothedSpeedMps)
        : '—';
    return _NotifContent(
      'Aproximando: ${nearest.nome}',
      'ETA $etaStr · $speedStr',
    );
  }

  return _NotifContent(
    'Amazon Track Data — Rastreamento ativo',
    'Velocidade: $speedStr',
  );
}

String _formatEta(double seconds) {
  if (seconds.isInfinite || seconds.isNaN || seconds < 0) return '—';
  final totalMin = (seconds / 60).round();
  if (totalMin < 1) return '< 1 min';
  if (totalMin < 60) return '$totalMin min';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}min';
}
