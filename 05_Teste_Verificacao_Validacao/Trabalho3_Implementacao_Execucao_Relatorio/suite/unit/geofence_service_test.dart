// Casos CT-GEO-01..09, CT-PAS-05 e CT-UI-04 — valor-limite e transição de
// estados do GeofenceService real (EAPT-ATD-001, seções 3.2 e 3.3).
//
// Porto de referência: Pier Urbano de Itacoatiara (id 1), atracação 250 m,
// aproximação 1200 m. Posições geradas por deslocamento em latitude
// (1° = 111.319,49 m na esfera usada por Geolocator.distanceBetween).

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:amazon_track_data/core/services/geofence_service.dart';
import 'package:amazon_track_data/data/models/port_model.dart';

import '../helpers/test_env.dart';

const _lat = -3.148781;
const _lng = -58.449257;
const _mPorGrau = 111319.49;

final _geo = GeofenceService();
final _spy = NotificationSpy.instance;

GeofenceStatus _status() =>
    _geo.statusAtual[1] ?? GeofenceStatus.foraDaZona;

/// Move a embarcação para [metros] ao norte do porto 1.
Future<void> _em(double metros, {double speed = 3.0}) async {
  _geo.updatePosition(_lat + metros / _mPorGrau, _lng, speed);
  await settle(20);
}

Future<void> _sequencia(List<double> distancias) async {
  for (final d in distancias) {
    await _em(d);
  }
}

void main() {
  setUpAll(() => _spy.install());

  setUp(() async {
    _geo.disableNotifications(); // também reseta estado e debounce
    _spy.clear();
  });

  group('CT-GEO-01 classificação por distância (valor-limite)', () {
    final casos = {
      5000.0: GeofenceStatus.foraDaZona,
      1201.0: GeofenceStatus.foraDaZona,
      1199.0: GeofenceStatus.aproximando,
      251.0: GeofenceStatus.aproximando,
      249.0: GeofenceStatus.atracado,
      0.0: GeofenceStatus.atracado,
    };
    casos.forEach((d, esperado) {
      test('CT-GEO-01 $d m → ${esperado.label}', () async {
        _geo.resetStatus();
        await _em(d);
        expect(_status(), esperado);
      });
    });

    test('CT-GEO-01 a distância gerada corresponde ao valor pedido', () {
      final d = Geolocator.distanceBetween(
          _lat + 1199 / _mPorGrau, _lng, _lat, _lng);
      expect(d, closeTo(1199, 0.5));
    });
  });

  test('CT-GEO-02 cruzar 1200 m notifica aproximação uma única vez', () async {
    _geo.enableNotifications();
    await _sequencia([3000, 2000, 800, 700]);
    expect(_status(), GeofenceStatus.aproximando);
    expect(_spy.titles, ['Aproximando-se do Porto']);
  });

  test('CT-GEO-03 cruzar 250 m em seguida notifica atracação', () async {
    _geo.enableNotifications();
    await _sequencia([2000, 1000, 600, 240, 100]);
    expect(_status(), GeofenceStatus.atracado);
    expect(_spy.titles, contains('Atracado no Porto'));
  });

  group('CT-GEO-04 ruído de ±5 m no limite de 1200 m', () {
    test('CT-GEO-04 no máximo 1 notificação em 10 leituras', () async {
      _geo.enableNotifications();
      await _em(3000);
      for (var i = 0; i < 10; i++) {
        await _em(i.isEven ? 1195 : 1205);
      }
      expect(_spy.shown.length, lessThanOrEqualTo(1));
    });

    test('CT-GEO-04 estado não alterna a cada leitura (histerese)', () async {
      await _em(3000);
      var transicoes = 0;
      var anterior = _status();
      for (var i = 0; i < 10; i++) {
        await _em(i.isEven ? 1195 : 1205);
        if (_status() != anterior) transicoes++;
        anterior = _status();
      }
      expect(transicoes, lessThanOrEqualTo(1));
    });
  });

  group('CT-GEO-05 / CT-GEO-06 ETA', () {
    GeofenceEvent evento(double metros, double speed) =>
        _geo.getPortoMaisProximo(_lat + metros / _mPorGrau, _lng, speed)!;

    test('CT-GEO-05 ETA indisponível a 0 e 0,49 m/s; calculado a 0,50', () {
      expect(evento(1000, 0).etaSegundos, isNull);
      expect(evento(1000, 0).etaFormatado, '—');
      expect(evento(1000, 0.49).etaSegundos, isNull);
      expect(evento(1000, 0.50).etaSegundos, closeTo(2000, 20));
    });

    test('CT-GEO-06 900 m a 5 m/s → 180 s ± 1 % e "3 min"', () {
      final e = evento(900, 5);
      expect(e.etaSegundos, closeTo(180, 1.8));
      expect(e.etaFormatado, '3 min');
    });

    test('CT-GEO-06 formatação: 20 s → "< 1 min"; 3720 s → "1h 02min"', () {
      final porto = AmazonPorts.all.first;
      GeofenceEvent comEta(double s) => GeofenceEvent(
            porto: porto,
            status: GeofenceStatus.aproximando,
            distanciaMetros: 100,
            etaSegundos: s,
            velocidadeMps: 5,
          );
      expect(comEta(20).etaFormatado, '< 1 min');
      expect(comEta(3720).etaFormatado, '1h 02min');
    });
  });

  test('CT-GEO-07 catálogo com 13 portos íntegros e sem sobreposição', () {
    const portos = AmazonPorts.all;
    expect(portos, hasLength(13));
    expect(portos.map((p) => p.id).toSet(), hasLength(13));
    expect(portos.map((p) => p.nome).toSet(), hasLength(13));
    for (final p in portos) {
      expect(p.raioAtracacao, lessThan(p.raioAproximacao), reason: p.nome);
      expect(p.latitude, inInclusiveRange(-10, 3), reason: p.nome);
      expect(p.longitude, inInclusiveRange(-75, -48), reason: p.nome);
    }
    for (var i = 0; i < portos.length; i++) {
      for (var j = i + 1; j < portos.length; j++) {
        final a = portos[i], b = portos[j];
        final d = Geolocator.distanceBetween(
            a.latitude, a.longitude, b.latitude, b.longitude);
        expect(d, greaterThan(a.raioAproximacao + b.raioAproximacao),
            reason: '${a.nome} × ${b.nome}');
      }
    }
  });

  test('CT-GEO-08 sem acompanhamento não há notificação', () async {
    await _sequencia([2000, 100, 2000]);
    expect(_spy.shown, isEmpty);
  });

  test('CT-GEO-09 saída do porto notifica "Saiu do Porto" sem anunciar '
      'aproximação', () async {
    await _em(100); // embarcação já atracada antes do acompanhamento
    expect(_status(), GeofenceStatus.atracado);
    _geo.enableNotifications();
    await _sequencia([600, 1500]);
    expect(_spy.titles, contains('Saiu do Porto'));
    expect(_spy.titles, isNot(contains('Aproximando-se do Porto')));
  });

  test('CT-PAS-05 desativar alertas reinicia o estado e silencia', () async {
    _geo.enableNotifications();
    await _em(800);
    expect(_spy.shown, hasLength(1));
    _geo.disableNotifications();
    expect(_geo.statusAtual, isEmpty);
    _spy.clear();
    await _sequencia([3000, 800, 100]);
    expect(_spy.shown, isEmpty);
  });

  test('CT-UI-04 números em pt-BR: "1,5 km" e "12,6 km/h"', () {
    final e = GeofenceEvent(
      porto: AmazonPorts.all.first,
      status: GeofenceStatus.foraDaZona,
      distanciaMetros: 1500,
      velocidadeMps: 3.5,
    );
    expect(e.distanciaFormatada, '1,5 km');
    expect(e.velocidadeKmhFormatada, '12,6 km/h');
  });
}
