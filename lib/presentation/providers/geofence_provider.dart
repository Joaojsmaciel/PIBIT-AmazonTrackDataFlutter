import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amazon_track_data/core/services/geofence_service.dart';
import 'package:amazon_track_data/core/services/notification_service.dart';
import 'package:amazon_track_data/core/services/offline_sync_service.dart';
import 'package:amazon_track_data/data/models/port_model.dart';

// ---------------------------------------------------------------------------
// Singletons de serviço
// ---------------------------------------------------------------------------

/// Provider do [GeofenceService] — singleton reutilizado durante toda a sessão.
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final service = GeofenceService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider do [NotificationService] — singleton já inicializado em [main()].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider do [OfflineSyncService] — singleton já inicializado em [main()].
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

// ---------------------------------------------------------------------------
// Dados dos portos
// ---------------------------------------------------------------------------

/// Lista imutável de todos os portos cadastrados no Amazonas.
final portosProvider = Provider<List<PortModel>>((ref) {
  return AmazonPorts.all;
});

// ---------------------------------------------------------------------------
// Eventos de geofence em tempo real
// ---------------------------------------------------------------------------

/// Stream de [GeofenceEvent]s emitidos durante o rastreamento ativo.
///
/// Emite sempre que a embarcação muda de estado em relação a um porto
/// (aproximação, atracação, saída) ou enquanto permanece numa zona relevante.
final geofenceEventsProvider = StreamProvider<GeofenceEvent>((ref) {
  final service = ref.watch(geofenceServiceProvider);
  return service.events;
});

/// Guarda o evento de geofence mais recente para exibição no UI.
/// Atualizado pelo [MapScreen] via [ref.listen].
final latestGeofenceEventProvider = StateProvider<GeofenceEvent?>((ref) => null);

// ---------------------------------------------------------------------------
// Contagem de pendentes offline
// ---------------------------------------------------------------------------

/// Stream com o número de pontos ainda não sincronizados.
/// Útil para exibir um badge ou indicador no UI.
final offlinePendingCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.pendingCount;
});

/// ID do barco que o passageiro escolheu acompanhar.
/// [null] = nenhum barco sendo acompanhado.
final watchedBoatIdProvider = StateProvider<String?>((ref) => null);

/// Indica se há conectividade de internet no momento.
final hasConnectivityProvider = Provider<bool>((ref) {
  return OfflineSyncService().isConnected;
});
