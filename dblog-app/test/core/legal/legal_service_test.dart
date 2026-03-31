import 'package:flutter_test/flutter_test.dart';

import 'package:dblog_app/core/legal/legal_service.dart';
import 'package:dblog_app/core/legal/data/spain_regulations.dart';
import 'package:dblog_app/core/legal/models/verdict_result.dart';

void main() {
  group('LegalService - detectTimePeriod', () {
    final service = LegalService.instance;

    test('detecta franja diurna (7:00 - 18:59)', () {
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 7, 0)),
        'diurno',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 12, 0)),
        'diurno',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 18, 59)),
        'diurno',
      );
    });

    test('detecta franja evening (19:00 - 22:59)', () {
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 19, 0)),
        'evening',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 21, 30)),
        'evening',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 22, 59)),
        'evening',
      );
    });

    test('detecta franja nocturna (23:00 - 6:59)', () {
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 23, 0)),
        'nocturno',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 0, 0)),
        'nocturno',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 3, 30)),
        'nocturno',
      );
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 6, 59)),
        'nocturno',
      );
    });

    test('limites exactos de franja horaria', () {
      // 7:00 es diurno.
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 7, 0)),
        'diurno',
      );
      // 6:59 es nocturno.
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 6, 59)),
        'nocturno',
      );
      // 19:00 es evening.
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 19, 0)),
        'evening',
      );
      // 23:00 es nocturno.
      expect(
        service.detectTimePeriod(now: DateTime(2024, 1, 1, 23, 0)),
        'nocturno',
      );
    });
  });

  group('LegalService - timePeriodLabel', () {
    final service = LegalService.instance;

    test('retorna etiqueta correcta para cada franja', () {
      expect(service.timePeriodLabel('diurno'), 'Diurno (7:00 - 19:00)');
      expect(service.timePeriodLabel('evening'), 'Evening (19:00 - 23:00)');
      expect(service.timePeriodLabel('nocturno'), 'Nocturno (23:00 - 7:00)');
    });

    test('retorna el valor tal cual si no coincide', () {
      expect(service.timePeriodLabel('desconocido'), 'desconocido');
    });
  });

  group('SpainRegulations - lookup offline', () {
    test('retorna limite correcto para zona residencial diurna exterior', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'residencial',
        timePeriod: 'diurno',
        noiseType: 'exterior',
      );
      expect(limit, 65.0);
    });

    test('retorna limite correcto para zona residencial nocturna exterior', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'residencial',
        timePeriod: 'nocturno',
        noiseType: 'exterior',
      );
      expect(limit, 55.0);
    });

    test('retorna limite correcto para zona comercial interior', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'comercial',
        timePeriod: 'diurno',
        noiseType: 'interior',
      );
      expect(limit, 45.0);
    });

    test('retorna limite correcto para zona industrial nocturna interior', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'industrial',
        timePeriod: 'nocturno',
        noiseType: 'interior',
      );
      expect(limit, 40.0);
    });

    test('retorna null para zona desconocida', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'imaginaria',
        timePeriod: 'diurno',
        noiseType: 'exterior',
      );
      expect(limit, isNull);
    });

    test('retorna null para franja desconocida', () {
      final limit = SpainRegulations.getLimit(
        zoneType: 'residencial',
        timePeriod: 'amanecer',
        noiseType: 'exterior',
      );
      expect(limit, isNull);
    });

    test('nombre de regulacion es Ley 37/2003', () {
      expect(
        SpainRegulations.regulationName,
        contains('Ley 37/2003'),
      );
    });

    test('municipios contiene al menos el fallback', () {
      expect(
        SpainRegulations.municipalities,
        contains('Espana (Ley 37/2003)'),
      );
    });
  });

  group('LegalService - computeVerdictOffline', () {
    final service = LegalService.instance;

    test('veredicto SUPERA cuando medicion excede limite', () {
      final result = service.computeVerdictOffline(
        municipality: 'Madrid',
        zoneType: 'residencial',
        timePeriod: 'nocturno',
        noiseType: 'exterior',
        measuredDb: 60.0,
      );
      expect(result, isNotNull);
      expect(result!.verdict, VerdictType.supera);
      expect(result.limitDb, 55.0);
      expect(result.differenceDb, 5.0);
    });

    test('veredicto CERCANO cuando medicion esta dentro de 5 dB', () {
      final result = service.computeVerdictOffline(
        municipality: 'Madrid',
        zoneType: 'residencial',
        timePeriod: 'nocturno',
        noiseType: 'exterior',
        measuredDb: 52.0,
      );
      expect(result, isNotNull);
      expect(result!.verdict, VerdictType.cercano);
    });

    test('veredicto NO_SUPERA cuando medicion esta muy por debajo', () {
      final result = service.computeVerdictOffline(
        municipality: 'Madrid',
        zoneType: 'residencial',
        timePeriod: 'nocturno',
        noiseType: 'exterior',
        measuredDb: 40.0,
      );
      expect(result, isNotNull);
      expect(result!.verdict, VerdictType.noSupera);
    });

    test('retorna null para combinacion invalida', () {
      final result = service.computeVerdictOffline(
        municipality: 'Madrid',
        zoneType: 'parque',
        timePeriod: 'nocturno',
        noiseType: 'exterior',
        measuredDb: 60.0,
      );
      expect(result, isNull);
    });

    test('resultado incluye nombre de regulacion y articulo', () {
      final result = service.computeVerdictOffline(
        municipality: 'Barcelona',
        zoneType: 'comercial',
        timePeriod: 'diurno',
        noiseType: 'exterior',
        measuredDb: 72.0,
      );
      expect(result, isNotNull);
      expect(result!.regulationName, contains('Ley 37/2003'));
      expect(result.article, isNotNull);
      expect(result.municipality, 'Barcelona');
      expect(result.timePeriod, 'diurno');
    });
  });
}
