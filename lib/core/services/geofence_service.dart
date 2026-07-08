import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:amazon_track_data/core/services/notification_service.dart';
import 'package:amazon_track_data/data/models/port_model.dart';

/// Evento emitido pelo [GeofenceService] sempre que a embarcação muda de
/// estado em relação a um porto (aproximação, atracação ou saída) **ou**
/// enquanto permanece dentro de uma zona de interesse (atualizações contínuas
/// de distância e ETA durante o rastreamento).
class GeofenceEvent {
  final PortModel porto;
  final GeofenceStatus status;

  /// Distância até o centro do porto em metros.
  final double distanciaMetros;

  /// Estimativa de chegada em segundos. [null] quando a embarcação está parada.
  final double? etaSegundos;

  /// Velocidade atual em metros por segundo.
  final double velocidadeMps;

  const GeofenceEvent({
    required this.porto,
    required this.status,
    required this.distanciaMetros,
    this.etaSegundos,
    required this.velocidadeMps,
  });

  /// Distância formatada para exibição no UI.
  String get distanciaFormatada {
    if (distanciaMetros < 1000) {
      return '${distanciaMetros.toStringAsFixed(0)} m';
    }
    return '${(distanciaMetros / 1000).toStringAsFixed(1)} km';
  }

  /// ETA formatado para exibição no UI.
  String get etaFormatado {
    if (etaSegundos == null ||
        etaSegundos!.isInfinite ||
        etaSegundos!.isNaN) {
      return '—';
    }
    final totalMin = (etaSegundos! / 60).round();
    if (totalMin < 1) return '< 1 min';
    if (totalMin < 60) return '$totalMin min';
    final horas = totalMin ~/ 60;
    final restMin = totalMin % 60;
    return '${horas}h ${restMin.toString().padLeft(2, '0')}min';
  }

  /// Velocidade em km/h para exibição.
  String get velocidadeKmhFormatada =>
      '${(velocidadeMps * 3.6).toStringAsFixed(1)} km/h';
}

/// Serviço de geofencing para portos fluviais do Amazonas.
///
/// ## Responsabilidades
/// - Receber atualizações de posição via [updatePosition].
/// - Calcular a distância até cada porto registrado.
/// - Gerenciar transições de estado (FORA_DA_ZONA → APROXIMANDO → ATRACADO).
/// - Disparar notificações com debounce para evitar spam.
/// - Emitir [GeofenceEvent]s pelo stream [events].
///
/// ## Uso
/// ```dart
/// // Inicializado automaticamente como singleton
/// final geofenceService = GeofenceService();
///
/// // Durante o rastreamento, a cada nova posição GPS:
/// geofenceService.updatePosition(lat, lon, speedMps);
///
/// // Ouvir eventos no UI:
/// geofenceService.events.listen((event) { ... });
/// ```
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final NotificationService _notificationService = NotificationService();

  final List<PortModel> _portos = AmazonPorts.all;

  final StreamController<GeofenceEvent> _eventController =
      StreamController<GeofenceEvent>.broadcast();

  /// Stream de eventos de geofence. Emite sempre que há mudança de estado
  /// ou enquanto a embarcação permanece numa zona de interesse.
  Stream<GeofenceEvent> get events => _eventController.stream;

  /// Estado atual de cada porto: id → [GeofenceStatus].
  final Map<int, GeofenceStatus> _statusMap = {};

  /// Timestamp da última notificação enviada por porto (para debounce).
  final Map<int, DateTime> _lastNotificationTime = {};

  /// Intervalo mínimo entre notificações do mesmo porto para evitar spam.
  static const Duration _debounceDuration = Duration(minutes: 3);

  /// Controla se notificações devem ser disparadas.
  /// Ativado apenas quando um passageiro seleciona um barco para acompanhar.
  bool _notificationsEnabled = false;

  /// Processa uma nova posição GPS da embarcação.
  ///
  /// Deve ser chamado a cada atualização de posição durante o rastreamento.
  /// [speedMps] é a velocidade atual em metros/segundo.
  void updatePosition(double latitude, double longitude, double speedMps) {
    for (final porto in _portos) {
      final distancia = Geolocator.distanceBetween(
        latitude,
        longitude,
        porto.latitude,
        porto.longitude,
      );

      final novoStatus = _calcularStatus(porto, distancia);
      final statusAnterior =
          _statusMap[porto.id] ?? GeofenceStatus.foraDaZona;

      if (novoStatus != statusAnterior) {
        _statusMap[porto.id] = novoStatus;
        _processarTransicao(
          porto: porto,
          statusAnterior: statusAnterior,
          novoStatus: novoStatus,
          distanciaMetros: distancia,
          velocidadeMps: speedMps,
        );
      }

      // Emite atualização contínua apenas para zonas relevantes
      if (novoStatus != GeofenceStatus.foraDaZona) {
        final eta = _calcularEta(distancia, speedMps);
        _emit(GeofenceEvent(
          porto: porto,
          status: novoStatus,
          distanciaMetros: distancia,
          etaSegundos: eta,
          velocidadeMps: speedMps,
        ));
      }
    }
  }

  /// Retorna o porto mais próximo atualmente dentro de alguma zona de interesse,
  /// ou [null] se nenhum porto estiver próximo. Útil para consulta pontual.
  GeofenceEvent? getPortoMaisProximo(
    double latitude,
    double longitude,
    double speedMps,
  ) {
    GeofenceEvent? closest;
    double minDistancia = double.infinity;

    for (final porto in _portos) {
      final distancia = Geolocator.distanceBetween(
        latitude,
        longitude,
        porto.latitude,
        porto.longitude,
      );

      if (distancia < porto.raioAproximacao && distancia < minDistancia) {
        minDistancia = distancia;
        closest = GeofenceEvent(
          porto: porto,
          status: _calcularStatus(porto, distancia),
          distanciaMetros: distancia,
          etaSegundos: _calcularEta(distancia, speedMps),
          velocidadeMps: speedMps,
        );
      }
    }
    return closest;
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  GeofenceStatus _calcularStatus(PortModel porto, double distancia) {
    if (distancia <= porto.raioAtracacao) return GeofenceStatus.atracado;
    if (distancia <= porto.raioAproximacao) return GeofenceStatus.aproximando;
    return GeofenceStatus.foraDaZona;
  }

  /// ETA em segundos ou [null] se a embarcação estiver praticamente parada.
  double? _calcularEta(double distanciaMetros, double speedMps) {
    if (speedMps < 0.5) return null;
    return distanciaMetros / speedMps;
  }

  void _processarTransicao({
    required PortModel porto,
    required GeofenceStatus statusAnterior,
    required GeofenceStatus novoStatus,
    required double distanciaMetros,
    required double velocidadeMps,
  }) {
    debugPrint(
      '[GeofenceService] ${porto.nome}: '
      '${statusAnterior.label} → ${novoStatus.label} '
      '(dist: ${distanciaMetros.toStringAsFixed(0)}m)',
    );

    if (!_notificationsEnabled) return;

    switch (novoStatus) {
      case GeofenceStatus.aproximando:
        if (_podeNotificar(porto.id)) {
          _notificationService.showApproaching(porto.nome);
          _registrarNotificacao(porto.id);
        }
        break;

      case GeofenceStatus.atracado:
        if (_podeNotificar(porto.id)) {
          _notificationService.showDocked(porto.nome);
          _registrarNotificacao(porto.id);
        }
        break;

      case GeofenceStatus.foraDaZona:
        // Só notifica saída se estava dentro de uma zona
        if (statusAnterior != GeofenceStatus.foraDaZona &&
            _podeNotificar(porto.id)) {
          _notificationService.showDeparted(porto.nome);
          _registrarNotificacao(porto.id);
        }
        break;
    }
  }

  bool _podeNotificar(int portoId) {
    final lastTime = _lastNotificationTime[portoId];
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime) > _debounceDuration;
  }

  void _registrarNotificacao(int portoId) {
    _lastNotificationTime[portoId] = DateTime.now();
  }

  void _emit(GeofenceEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Cópia imutável da lista de portos.
  List<PortModel> get portos => List.unmodifiable(_portos);

  /// Cópia imutável do status atual por porto.
  Map<int, GeofenceStatus> get statusAtual => Map.unmodifiable(_statusMap);

  /// Ativa notificações — chamado quando o passageiro seleciona um barco.
  void enableNotifications() {
    _notificationsEnabled = true;
    debugPrint('[GeofenceService] Notificações ativadas.');
  }

  /// Desativa notificações e reseta o estado.
  void disableNotifications() {
    _notificationsEnabled = false;
    resetStatus();
    debugPrint('[GeofenceService] Notificações desativadas.');
  }

  /// Reseta o estado interno — útil ao finalizar uma viagem.
  void resetStatus() {
    _statusMap.clear();
    _lastNotificationTime.clear();
    debugPrint('[GeofenceService] Estado resetado.');
  }

  void dispose() {
    _eventController.close();
    debugPrint('[GeofenceService] Dispose.');
  }
}
