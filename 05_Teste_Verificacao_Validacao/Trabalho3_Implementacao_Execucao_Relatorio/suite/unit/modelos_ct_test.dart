// Casos sobre modelos e cálculos puros (oráculo calculado):
// CT-RAS-10, CT-RAS-12, CT-EMB-01, CT-EMB-08, CT-EMB-10, CT-HCH-02,
// CT-HCH-05..07, CT-AGE-01, CT-AGE-03, CT-AGE-05, CT-PAS-04.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:amazon_track_data/core/utils/kalman_filter.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/chat_conversation.dart';
import 'package:amazon_track_data/data/models/chat_message.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/scheduled_trip.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';

const _baseTs = 1757239200000; // 07/09/2026 10:00 UTC (EAPT, seção 8)

LocationModel _ponto({String boatId = 'boat-a', double speed = 3.0}) =>
    LocationModel(
      userId: 'uid-barqueiro-a',
      tripId: 'trip-1',
      boatId: boatId,
      latitude: -3.148781,
      longitude: -58.449257,
      speed: speed,
      accuracy: 8,
      timestamp: _baseTs,
      userType: 'barqueiro',
      userName: 'Barqueiro A',
    );

StopModel _stop(String id, String name) => StopModel(
      id: id,
      name: name,
      city: name,
      latitude: -3.1,
      longitude: -58.4,
      radius: 500,
      type: StopType.porto,
    );

void main() {
  group('CT-RAS-10 filtro de Kalman', () {
    test('CT-RAS-10 converge para 5 m/s após 60 leituras constantes', () {
      final kf = KalmanFilter(initialValue: 0);
      double v = 0;
      for (var i = 0; i < 60; i++) {
        v = kf.update(5.0);
      }
      expect(v, closeTo(5.0, 0.05));
    });

    test('CT-RAS-10 reduz a variância de uma série ruidosa', () {
      final rnd = Random(42);
      final kf = KalmanFilter(initialValue: 5.0);
      final raw = <double>[];
      final filtered = <double>[];
      for (var i = 0; i < 200; i++) {
        final z = 5.0 + (rnd.nextDouble() - 0.5) * 4; // ±2 m/s
        raw.add(z);
        filtered.add(kf.update(z));
      }
      double variance(List<double> xs) {
        final m = xs.reduce((a, b) => a + b) / xs.length;
        return xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) /
            xs.length;
      }

      expect(variance(filtered.skip(20).toList()),
          lessThan(variance(raw.skip(20).toList())));
    });

    test('CT-RAS-10 reset reinicia estimativa e covariância', () {
      final kf = KalmanFilter(initialValue: 0);
      for (var i = 0; i < 10; i++) {
        kf.update(8);
      }
      kf.reset(initialValue: 0);
      expect(kf.value, 0);
      expect(kf.errorCovariance, 1.0);
    });
  });

  group('CT-RAS-12 vínculo do ponto com a embarcação (RN-06)', () {
    test('CT-RAS-12 copyWith preserva boatId', () {
      final p = _ponto();
      expect(p.copyWith(speed: 4.2).boatId, 'boat-a');
    });

    test('CT-RAS-12 pontos de embarcações diferentes não são iguais', () {
      expect(_ponto(boatId: 'boat-a') == _ponto(boatId: 'boat-b'), isFalse);
    });
  });

  group('CT-EMB-01 / CT-EMB-10 embarcação', () {
    test('CT-EMB-01 embarcação nova fica vinculada ao dono e ativa', () {
      const boat = BoatModel(
        id: 'boat-a',
        ownerId: 'uid-barqueiro-a',
        ownerName: 'Barqueiro A',
        name: 'Comandante Silva',
        routes: [],
        capacity: 120,
        type: 'Lancha',
        createdAt: _baseTs,
      );
      final map = boat.toMap();
      expect(map['ownerId'], 'uid-barqueiro-a');
      expect(map['isActive'], isTrue);
      expect(map['capacity'], 120);
      expect(BoatModel.fromMap(map), boat);
    });

    test('CT-EMB-10 documentos incompletos não geram IDs nulos', () {
      final boat = BoatModel.fromMap(const {});
      expect(boat.id, isNotNull);
      expect(boat.ownerId, isNotNull);
      expect(boat.id, isEmpty);
      final user = UserModel.fromMap(const {});
      expect(user.uid, isEmpty);
      final loc = LocationModel.fromMap(const {});
      expect(loc.userId, isEmpty);
      expect(loc.tripId, isEmpty);
      final route = RouteModel.fromMap(const {});
      expect(route.id, isEmpty);
      expect(route.origin.id, isEmpty);
    });
  });

  test('CT-EMB-08 rota expõe origem, destino, paradas e duração', () {
    final route = RouteModel(
      id: 'r1',
      ownerId: 'uid-barqueiro-a',
      name: 'Itacoatiara → Manaus',
      origin: _stop('s1', 'Itacoatiara'),
      destination: _stop('s3', 'Manaus'),
      stops: [_stop('s2', 'Silves')],
      estimatedDurationMinutes: 480,
      createdAt: _baseTs,
    );
    final back = RouteModel.fromMap(route.toMap());
    expect(back.origin.name, 'Itacoatiara');
    expect(back.destination.name, 'Manaus');
    expect(back.stops.map((s) => s.name), ['Silves']);
    expect(back.estimatedDurationMinutes, 480);
    expect(back.isActive, isTrue);
  });

  test('CT-HCH-02 dados da viagem: 2 h, 36 km, 18 km/h', () {
    const trip = TripSummary(
      tripId: 't1',
      userId: 'uid-barqueiro-a',
      userName: 'Barqueiro A',
      boatId: 'boat-a',
      startTimestamp: _baseTs,
      endTimestamp: _baseTs + 2 * 3600 * 1000,
      startLat: 0,
      startLng: 0,
      endLat: 0,
      endLng: 0,
      pointCount: 1440,
      avgSpeedMs: 5,
      totalDistanceMeters: 36000,
      departurePoint: 'Itacoatiara',
      arrivalPoint: 'Manaus',
    );
    expect(trip.duration, const Duration(hours: 2));
    expect(trip.totalDistanceKm, 36);
    expect(trip.avgSpeedKmh, closeTo(18, 1e-9));
    expect(trip.departurePoint, 'Itacoatiara');
    expect(trip.arrivalPoint, 'Manaus');
  });

  group('CT-HCH-05..07 chat', () {
    test('CT-HCH-05 ID de conversa é determinístico e ordenado', () {
      final a = ChatMessage.buildChatId('uid-passageiro-b', 'uid-barqueiro-a');
      final b = ChatMessage.buildChatId('uid-barqueiro-a', 'uid-passageiro-b');
      expect(a, b);
      expect(a, 'uid-barqueiro-a_uid-passageiro-b');
    });

    test('CT-HCH-06 lista de conversas identifica o outro participante', () {
      final conv = ChatConversation.fromMap('uidA_uidB', {
        'participantNames': {'uidA': 'Barqueiro A', 'uidB': 'Passageiro B'},
        'lastMessage': 'Que horas sai?',
        'lastSenderId': 'uidB',
        'lastSenderName': 'Passageiro B',
        'lastTimestamp': _baseTs,
      });
      expect(conv.participants, ['uidA', 'uidB']);
      expect(conv.otherName('uidA'), 'Passageiro B');
      expect(conv.otherId('uidA'), 'uidB');
      expect(conv.lastMessage, 'Que horas sai?');
      expect(conv.lastTimestamp, _baseTs);
    });

    test('CT-HCH-06 nome ausente usa o fallback "Usuário"', () {
      final conv = ChatConversation.fromMap('uidA_uidB', {});
      expect(conv.otherName('uidA'), 'Usuário');
    });

    test('CT-HCH-07 mensagem registra os campos obrigatórios', () {
      const msg = ChatMessage(
        id: 'm1',
        chatId: 'uidA_uidB',
        senderId: 'uidB',
        senderName: 'Passageiro B',
        text: 'Que horas sai?',
        timestamp: _baseTs,
      );
      final map = msg.toMap();
      for (final k in ['id', 'chatId', 'senderId', 'text', 'timestamp']) {
        expect(map[k], isNotNull, reason: k);
      }
      expect(map['isRead'], isFalse);
      final back = ChatMessage.fromMap(map);
      expect(back.text, msg.text);
      expect(back.timestamp, msg.timestamp);
    });
  });

  group('CT-AGE agenda', () {
    ScheduledTrip agenda({
      required int departure,
      bool cancelled = false,
      int? arrival,
    }) =>
        ScheduledTrip(
          id: 's1',
          boatId: 'boat-a',
          boatName: 'Comandante Silva',
          ownerId: 'uid-barqueiro-a',
          ownerName: 'Barqueiro A',
          departurePoint: 'Itacoatiara',
          arrivalPoint: 'Manaus',
          stops: const ['Silves'],
          departureDateMs: departure,
          estimatedArrivalMs: arrival,
          availableSeats: 40,
          isCancelled: cancelled,
          createdAt: _baseTs,
        );

    test('CT-AGE-01 agenda válida fica vinculada ao dono e à data', () {
      final amanha = DateTime.now().add(const Duration(days: 1));
      final s = agenda(
        departure: amanha.millisecondsSinceEpoch,
        arrival: amanha.add(const Duration(hours: 8)).millisecondsSinceEpoch,
      );
      expect(s.toMap()['ownerId'], 'uid-barqueiro-a');
      expect(s.departureDate.day, amanha.day);
      expect(s.estimatedArrival!.difference(s.departureDate),
          const Duration(hours: 8));
    });

    test('CT-AGE-03 só a agenda futura e não cancelada é "futura"', () {
      final agora = DateTime.now().millisecondsSinceEpoch;
      final h = const Duration(hours: 1).inMilliseconds;
      expect(agenda(departure: agora + h).isUpcoming, isTrue);
      expect(agenda(departure: agora - h).isUpcoming, isFalse);
      expect(agenda(departure: agora + h, cancelled: true).isUpcoming, isFalse);
    });

    test('CT-AGE-05 round-trip preserva campos', () {
      final s = agenda(departure: _baseTs, arrival: _baseTs + 1000);
      final back = ScheduledTrip.fromMap('s1', s.toMap());
      expect(back.toMap(), s.toMap());
    });

    test('CT-AGE-05 documento só com a data usa padrões seguros', () {
      final s = ScheduledTrip.fromMap('x', {'departureDateMs': _baseTs});
      expect(s.departureDateMs, _baseTs);
      expect(s.stops, isEmpty);
      expect(s.estimatedArrivalMs, isNull);
      expect(s.availableSeats, isNull);
      expect(s.isCancelled, isFalse);
      expect(s.notes, '');
    });
  });

  group('CT-PAS-04 indicadores da viagem ativa', () {
    // Destino ~9 km ao norte do ponto atual.
    const lat0 = -3.148781, lng0 = -58.449257;
    const latDest = lat0 + 9000 / 111319.49;

    ActiveTripInfo info({
      double speed = 5,
      int startMinAgo = 30,
      int duration = 120,
      double? dLat,
      double? dLng,
    }) =>
        ActiveTripInfo(
          captainName: 'Barqueiro A',
          departurePoint: 'Itacoatiara',
          arrivalPoint: 'Manaus',
          stops: const [],
          speedMs: speed,
          currentLatitude: lat0,
          currentLongitude: lng0,
          currentTimestamp: DateTime.now().millisecondsSinceEpoch,
          startTimestamp: DateTime.now()
              .subtract(Duration(minutes: startMinAgo))
              .millisecondsSinceEpoch,
          estimatedDurationMinutes: duration,
          destinationLatitude: dLat,
          destinationLongitude: dLng,
        );

    // Oráculo em pt-BR (RI-08, CT-UI-04): vírgula decimal. A v2.0 da suíte
    // esperava '18.0', que fixava o defeito DEF-18 no próprio teste.
    test('CT-PAS-04 velocidade em km/h com 1 casa e nunca negativa', () {
      expect(info(speed: 5).speedKmh, '18,0');
      expect(info(speed: -1).speedKmh, '0,0');
    });

    test('CT-PAS-04 progresso ≈ 25 % após 30 de 120 min', () {
      expect(info().progress, closeTo(0.25, 0.01));
    });

    test('CT-PAS-04 distância ≈ 9 km e tempo ≈ 30 min a 5 m/s', () {
      final i = info(dLat: latDest, dLng: lng0);
      expect(i.distanceRemainingMeters, closeTo(9000, 90));
      expect(i.remainingDuration!.inMinutes, inInclusiveRange(29, 31));
    });

    test('CT-PAS-04 abaixo de 0,5 m/s usa o horário planejado', () {
      final i = info(speed: 0.3, dLat: latDest, dLng: lng0);
      expect(i.remainingDuration!.inMinutes, inInclusiveRange(89, 90));
    });

    test('CT-PAS-04 destino inválido é ignorado', () {
      expect(info(dLat: 95, dLng: lng0).distanceRemainingMeters, isNull);
      expect(info(dLat: 0, dLng: 0).distanceRemainingMeters, isNull);
    });
  });
}
