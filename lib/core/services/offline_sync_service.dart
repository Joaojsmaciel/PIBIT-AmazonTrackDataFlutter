import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amazon_track_data/data/models/local_location_point.dart';

/// Callback invocado pelo [OfflineSyncService] ao tentar sincronizar um ponto
/// com o servidor. Deve retornar [true] em caso de sucesso, [false] em caso
/// de falha (o ponto permanecerá na fila para nova tentativa).
typedef SyncPointCallback = Future<bool> Function(LocalLocationPoint point);

/// Serviço offline-first para regiões de baixa conectividade da Amazônia.
///
/// ## Fluxo
/// 1. [savePoint] persiste o ponto em [SharedPreferences] imediatamente.
/// 2. Se houver internet, tenta enviar na hora.
/// 3. Se não houver, mantém na fila local.
/// 4. Quando a conectividade é restaurada → [_syncPending] é acionado.
/// 5. Um timer periódico de [_retryInterval] também tenta sincronizar.
///
/// ## Garantias
/// - Persistência entre reinicializações do app (SharedPreferences).
/// - Ordem cronológica respeitada (fila FIFO).
/// - Deduplicação por [LocalLocationPoint.id].
/// - Pontos sincronizados são removidos da fila.
/// - Lotes de no máximo [_maxBatchSize] por ciclo de sync.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _storageKey = 'amazon_offline_location_queue';
  static const Duration _retryInterval = Duration(seconds: 30);
  static const int _maxBatchSize = 50;

  SyncPointCallback? _syncCallback;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _retryTimer;

  bool _isSyncing = false;
  bool _hasConnectivity = false;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  /// Stream com o número atual de pontos pendentes de sincronização.
  Stream<int> get pendingCount => _pendingCountController.stream;

  bool get isConnected => _hasConnectivity;

  /// Inicializa o serviço.
  ///
  /// [onSync]: callback chamado ao tentar enviar cada ponto ao servidor.
  /// Deve ser chamado uma única vez em [main()], antes do [runApp].
  Future<void> initialize({required SyncPointCallback onSync}) async {
    _syncCallback = onSync;

    final result = await Connectivity().checkConnectivity();
    _hasConnectivity = _isConnected(result);
    debugPrint(
        '[OfflineSyncService] Inicializado. Conectado: $_hasConnectivity');

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    _retryTimer = Timer.periodic(_retryInterval, (_) {
      if (_hasConnectivity) _syncPending();
    });

    if (_hasConnectivity) {
      Future.delayed(const Duration(seconds: 3), _syncPending);
    }

    await _emitPendingCount();
  }

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  /// Persiste [point] na fila offline e, se houver internet, tenta enviar
  /// imediatamente ao servidor.
  Future<void> savePoint(LocalLocationPoint point) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = _loadQueue(prefs);

      // Deduplicação por id
      final alreadyExists = queue.any((p) => p.id == point.id);
      if (!alreadyExists) {
        queue.add(point);
        await _persistQueue(prefs, queue);
        debugPrint(
            '[OfflineSyncService] Ponto salvo (total pendente: ${queue.where((p) => !p.sincronizado).length})');
      }

      _emitPendingCount();

      if (_hasConnectivity) _syncPending();
    } catch (e) {
      debugPrint('[OfflineSyncService] Erro ao salvar ponto: $e');
    }
  }

  /// Retorna todos os pontos pendentes (não sincronizados) da fila.
  Future<List<LocalLocationPoint>> getPendingPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = _loadQueue(prefs);
      return queue.where((p) => !p.sincronizado).toList();
    } catch (e) {
      return [];
    }
  }

  /// Número de pontos pendentes de sincronização.
  Future<int> getPendingCount() async {
    final points = await getPendingPoints();
    return points.length;
  }

  /// Remove manualmente todos os pontos já sincronizados da fila local.
  Future<void> clearSynced() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = _loadQueue(prefs);
      final filtered = queue.where((p) => !p.sincronizado).toList();
      await _persistQueue(prefs, filtered);
      _emitPendingCount();
    } catch (e) {
      debugPrint('[OfflineSyncService] Erro ao limpar sincronizados: $e');
    }
  }

  /// Força uma tentativa de sincronização imediata (útil para testes e debug).
  Future<void> forcSync() => _syncPending();

  // ---------------------------------------------------------------------------
  // Sincronização
  // ---------------------------------------------------------------------------

  Future<void> _syncPending() async {
    if (_isSyncing || _syncCallback == null) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = _loadQueue(prefs);
      final pending = queue.where((p) => !p.sincronizado).toList();

      if (pending.isEmpty) return;

      debugPrint('[OfflineSyncService] Sincronizando ${pending.length} ponto(s)...');

      final batch = pending.take(_maxBatchSize).toList();
      int synced = 0;

      for (final point in batch) {
        try {
          final success = await _syncCallback!(point);
          if (success) {
            // Marca como sincronizado na fila em memória
            final idx = queue.indexWhere((p) => p.id == point.id);
            if (idx != -1) queue[idx].sincronizado = true;
            synced++;
          }
        } catch (e) {
          debugPrint('[OfflineSyncService] Falha ao sincronizar ponto ${point.id}: $e');
        }
      }

      // Remove os sincronizados e persiste
      queue.removeWhere((p) => p.sincronizado);
      await _persistQueue(prefs, queue);
      await _emitPendingCount();

      debugPrint(
          '[OfflineSyncService] $synced/${batch.length} pontos sincronizados. '
          'Restante: ${queue.length}');
    } catch (e) {
      debugPrint('[OfflineSyncService] Erro durante sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Conectividade
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasConnected = _hasConnectivity;
    _hasConnectivity = _isConnected(result);
    debugPrint('[OfflineSyncService] Conectividade: $_hasConnectivity');

    if (!wasConnected && _hasConnectivity) {
      debugPrint('[OfflineSyncService] Internet restaurada — iniciando sync...');
      _syncPending();
    }
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  // ---------------------------------------------------------------------------
  // Persistência (SharedPreferences)
  // ---------------------------------------------------------------------------

  List<LocalLocationPoint> _loadQueue(SharedPreferences prefs) {
    final rawList = prefs.getStringList(_storageKey) ?? [];
    final result = <LocalLocationPoint>[];
    for (final raw in rawList) {
      try {
        result.add(LocalLocationPoint.fromJson(
          json.decode(raw) as Map<String, dynamic>,
        ));
      } catch (e) {
        debugPrint('[OfflineSyncService] Registro corrompido ignorado: $e');
      }
    }
    return result;
  }

  Future<void> _persistQueue(
    SharedPreferences prefs,
    List<LocalLocationPoint> queue,
  ) async {
    final rawList = queue.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  Future<void> _emitPendingCount() async {
    final count = await getPendingCount();
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(count);
    }
  }

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _pendingCountController.close();
    debugPrint('[OfflineSyncService] Dispose.');
  }
}
