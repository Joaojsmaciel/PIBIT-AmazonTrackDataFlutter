import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço centralizado de notificações locais.
///
/// Dois canais Android:
///  - [_geofenceChannelId]: heads-up de alta prioridade para eventos de porto.
///  - [_trackingChannelId]: notificação persistente (ongoing) de baixa prioridade
///    que fica visível na barra de status enquanto o GPS está sendo coletado.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationIdCounter = 0;

  // ── Canal de alertas de porto (heads-up) ─────────────────────────────────
  static const String _geofenceChannelId = 'amazon_geofence_channel';
  static const String _geofenceChannelName = 'Alertas de Porto';
  static const String _geofenceChannelDesc =
      'Notificações sobre proximidade de portos fluviais do Amazonas';

  // ── Canal de rastreamento persistente ─────────────────────────────────────
  static const String _trackingChannelId = 'amazon_tracking_channel';
  static const String _trackingChannelName = 'Rastreamento de Embarcação';
  static const String _trackingChannelDesc =
      'Notificação persistente enquanto o rastreamento GPS está ativo.';

  /// ID fixo da notificação persistente de rastreamento.
  static const int trackingNotificationId = 888;

  // ─────────────────────────────────────────────────────────────────────────
  // Inicialização
  // ─────────────────────────────────────────────────────────────────────────

  /// Inicializa o plugin e cria ambos os canais Android.
  /// Deve ser chamado antes de [runApp], em [main()].
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Canal de alta prioridade — geofence
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _geofenceChannelId,
        _geofenceChannelName,
        description: _geofenceChannelDesc,
        importance: Importance.high,
      ),
    );

    // Canal de baixa prioridade — rastreamento persistente (sem som)
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _trackingChannelId,
        _trackingChannelName,
        description: _trackingChannelDesc,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );

    _initialized = true;
    debugPrint('[NotificationService] Inicializado com sucesso.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notificação persistente de rastreamento GPS
  // ─────────────────────────────────────────────────────────────────────────

  /// Exibe (ou atualiza) a notificação persistente na barra de status.
  ///
  /// Sempre usa [trackingNotificationId] = 888, portanto chamar novamente
  /// apenas atualiza o conteúdo sem criar duplicata.
  Future<void> showPersistentTracking({
    String title = 'Amazon Track Data',
    String body = 'Coletando localização GPS…',
  }) async {
    if (!_initialized) await initialize();

    await _plugin.show(
      trackingNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _trackingChannelId,
          _trackingChannelName,
          channelDescription: _trackingChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,       // não pode ser descartada pelo usuário
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/ic_launcher',
          // Ícone pequeno na barra de status (símbolo de localização)
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false, // não interrompe; apenas aparece na central
          presentSound: false,
          presentBadge: false,
        ),
      ),
    );
    debugPrint('[NotificationService] Notificação persistente: $title — $body');
  }

  /// Cancela a notificação persistente de rastreamento.
  Future<void> cancelPersistentTracking() async {
    await _plugin.cancel(trackingNotificationId);
    debugPrint('[NotificationService] Notificação persistente cancelada.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Alertas de porto (geofence)
  // ─────────────────────────────────────────────────────────────────────────

  /// Notifica que a embarcação está se aproximando de [nomePorto].
  Future<void> showApproaching(String nomePorto) => _showGeofence(
        title: 'Aproximando-se do Porto',
        body: 'Embarcação próxima ao $nomePorto',
      );

  /// Notifica que a embarcação atracou em [nomePorto].
  Future<void> showDocked(String nomePorto) => _showGeofence(
        title: 'Atracado no Porto',
        body: 'Embarcação chegou ao $nomePorto',
      );

  /// Notifica que a embarcação saiu de [nomePorto].
  Future<void> showDeparted(String nomePorto) => _showGeofence(
        title: 'Saiu do Porto',
        body: 'Embarcação saiu do $nomePorto',
      );

  Future<void> _showGeofence({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    final id = _notificationIdCounter++;
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _geofenceChannelId,
          _geofenceChannelName,
          channelDescription: _geofenceChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
    );
    debugPrint('[NotificationService] $title — $body');
  }
}
