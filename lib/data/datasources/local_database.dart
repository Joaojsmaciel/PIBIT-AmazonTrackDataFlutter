import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

// Simulação de banco de dados offline com Drift
// Para produção, usar properly implement Drift database
class LocalDatabaseService {
  // Cache em memória para dados offline
  static final List<Map<String, dynamic>> _cachedLocations = [];

  Future<void> insertLocation(LocationModel location) async {
    try {
      _cachedLocations.add({
        ...location.toMap(),
        'synced': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw LocalDatabaseFailure(
        message: 'Erro ao salvar localização offline',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllUnsynced() async {
    try {
      return _cachedLocations.where((loc) => !(loc['synced'] as bool? ?? false)).toList();
    } catch (e) {
      throw LocalDatabaseFailure(
        message: 'Erro ao buscar localizações não sincronizadas',
      );
    }
  }

  Future<void> markAsSynced(int index) async {
    try {
      if (index < _cachedLocations.length) {
        _cachedLocations[index]['synced'] = true;
      }
    } catch (e) {
      throw LocalDatabaseFailure(
        message: 'Erro ao marcar localização como sincronizada',
      );
    }
  }

  Future<void> deleteOlderThan(int timestamp) async {
    try {
      _cachedLocations.removeWhere((loc) => (loc['timestamp'] as int? ?? 0) < timestamp);
    } catch (e) {
      throw LocalDatabaseFailure(
        message: 'Erro ao deletar localizações antigas',
      );
    }
  }

  Future<void> clearAll() async {
    try {
      _cachedLocations.clear();
    } catch (e) {
      throw LocalDatabaseFailure(
        message: 'Erro ao limpar banco de dados',
      );
    }
  }

  void dispose() {
    _cachedLocations.clear();
  }
}
