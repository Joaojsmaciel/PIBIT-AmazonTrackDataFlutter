import 'package:equatable/equatable.dart';

/// Status de geofence de uma embarcação em relação a um porto.
enum GeofenceStatus {
  foraDaZona,
  aproximando,
  atracado,
}

extension GeofenceStatusExtension on GeofenceStatus {
  String get label {
    switch (this) {
      case GeofenceStatus.foraDaZona:
        return 'Fora da Zona';
      case GeofenceStatus.aproximando:
        return 'Aproximando';
      case GeofenceStatus.atracado:
        return 'Atracado';
    }
  }
}

/// Modelo de dados de um porto fluvial do Amazonas.
class PortModel extends Equatable {
  final int id;
  final String nome;
  final double latitude;
  final double longitude;

  /// Raio de aproximação em metros (zona externa).
  final double raioAproximacao;

  /// Raio de atracação em metros (zona interna).
  final double raioAtracacao;

  const PortModel({
    required this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.raioAproximacao,
    required this.raioAtracacao,
  });

  @override
  List<Object?> get props =>
      [id, nome, latitude, longitude, raioAproximacao, raioAtracacao];
}

/// Catálogo estático dos portos fluviais do Amazonas implementados.
class AmazonPorts {
  AmazonPorts._();

  static const List<PortModel> all = [
    PortModel(
      id: 1,
      nome: 'Pier Urbano de Itacoatiara',
      latitude: -3.148781,
      longitude: -58.449257,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 2,
      nome: 'Pier de Parintins',
      latitude: -2.62801,
      longitude: -56.73538,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 3,
      nome: 'Dock de Maués',
      latitude: -3.38354,
      longitude: -57.71820,
      raioAproximacao: 1000,
      raioAtracacao: 220,
    ),
    PortModel(
      id: 4,
      nome: 'Pier de Manacapuru',
      latitude: -3.29092,
      longitude: -60.62139,
      raioAproximacao: 1000,
      raioAtracacao: 220,
    ),
    PortModel(
      id: 5,
      nome: 'Dock Principal de Coari',
      latitude: -4.08582,
      longitude: -63.14138,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 6,
      nome: 'Pier de Tefé',
      latitude: -3.35531,
      longitude: -64.71001,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 7,
      nome: 'Porto Fluvial de Tabatinga',
      latitude: -4.24492,
      longitude: -69.93884,
      raioAproximacao: 1500,
      raioAtracacao: 300,
    ),
    PortModel(
      id: 8,
      nome: 'Pier de Barcelos',
      latitude: -0.97389,
      longitude: -62.92463,
      raioAproximacao: 1000,
      raioAtracacao: 220,
    ),
    PortModel(
      id: 9,
      nome: 'Dock de Humaitá',
      latitude: -7.50956,
      longitude: -63.02078,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 10,
      nome: 'Pier de Iranduba',
      latitude: -3.28347,
      longitude: -60.18684,
      raioAproximacao: 800,
      raioAtracacao: 180,
    ),
    PortModel(
      id: 11,
      nome: 'Porto de Santarém',
      latitude: -2.43260,
      longitude: -54.70850,
      raioAproximacao: 1500,
      raioAtracacao: 300,
    ),
    PortModel(
      id: 12,
      nome: 'Porto de Juruti',
      latitude: -2.15310,
      longitude: -56.08860,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
    PortModel(
      id: 13,
      nome: 'Porto de Óbidos',
      latitude: -1.91880,
      longitude: -55.52150,
      raioAproximacao: 1200,
      raioAtracacao: 250,
    ),
  ];
}
