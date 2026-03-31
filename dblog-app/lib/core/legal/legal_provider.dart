import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import 'data/spain_regulations.dart';
import 'legal_service.dart';
import 'models/verdict_result.dart';

/// ChangeNotifier que gestiona el estado legal:
/// municipio detectado, franja horaria, limite legal y veredicto.
class LegalProvider extends ChangeNotifier {
  final LegalService _service = LegalService.instance;
  final ApiService _api = ApiService.instance;

  // -- Estado --
  String? _municipality;
  String? get municipality => _municipality;

  bool _isManualMunicipality = false;
  bool get isManualMunicipality => _isManualMunicipality;

  String _timePeriod = 'diurno';
  String get timePeriod => _timePeriod;

  String _zoneType = 'residencial';
  String get zoneType => _zoneType;

  String _noiseType = 'exterior';
  String get noiseType => _noiseType;

  double? _currentLegalLimit;
  double? get currentLegalLimit => _currentLegalLimit;

  String? _regulationName;
  String? get regulationName => _regulationName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _locationDenied = false;
  bool get locationDenied => _locationDenied;

  /// Municipios disponibles para seleccion manual.
  List<String> get availableMunicipalities => SpainRegulations.municipalities;

  LegalProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _updateTimePeriod();
    await detectLocation();
    _updateLegalLimit();
  }

  /// Detecta el municipio via GPS.
  Future<void> detectLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final detected = await _service.detectMunicipality();
      if (detected != null && !_isManualMunicipality) {
        _municipality = detected;
        _locationDenied = false;
      } else if (detected == null && _municipality == null) {
        _locationDenied = true;
        // Fallback a la ley general.
        _municipality = SpainRegulations.fallbackMunicipality;
      }
    } catch (e) {
      log('Error detectando ubicacion: $e');
      _municipality ??= SpainRegulations.fallbackMunicipality;
    }

    _isLoading = false;
    _updateLegalLimit();
    notifyListeners();
  }

  /// Establece el municipio manualmente.
  void setMunicipality(String municipality) {
    _municipality = municipality;
    _isManualMunicipality = true;
    _updateLegalLimit();
    notifyListeners();
  }

  /// Vuelve a deteccion automatica de municipio.
  Future<void> resetToAutoDetect() async {
    _isManualMunicipality = false;
    await detectLocation();
  }

  /// Establece el tipo de zona.
  void setZoneType(String zoneType) {
    _zoneType = zoneType;
    _updateLegalLimit();
    notifyListeners();
  }

  /// Establece el tipo de ruido (interior/exterior).
  void setNoiseType(String noiseType) {
    _noiseType = noiseType;
    _updateLegalLimit();
    notifyListeners();
  }

  /// Actualiza la franja horaria segun la hora actual.
  void _updateTimePeriod() {
    _timePeriod = _service.detectTimePeriod();
  }

  /// Refresca la franja horaria (por si cambio la hora).
  void refreshTimePeriod() {
    final newPeriod = _service.detectTimePeriod();
    if (newPeriod != _timePeriod) {
      _timePeriod = newPeriod;
      _updateLegalLimit();
      notifyListeners();
    }
  }

  /// Actualiza el limite legal actual con datos offline.
  void _updateLegalLimit() {
    final limit = SpainRegulations.getLimit(
      zoneType: _zoneType,
      timePeriod: _timePeriod,
      noiseType: _noiseType,
    );
    _currentLegalLimit = limit;
    _regulationName = SpainRegulations.regulationName;
  }

  /// Obtiene el veredicto para una medicion dada.
  /// Intenta primero con el API, y si falla usa datos offline.
  Future<VerdictResult?> getVerdict(double measuredDb) async {
    if (_municipality == null) return null;

    // Intentar con el API.
    try {
      final queryParams = {
        'municipality': _municipality!,
        'zone_type': _zoneType,
        'time_period': _timePeriod,
        'noise_type': _noiseType,
        'measured_db': measuredDb.toString(),
      };

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final json = await _api.get('/regulations/verdict?$queryString');
      return VerdictResult.fromJson(json);
    } catch (e) {
      log('Error consultando API de veredicto, usando offline: $e');
    }

    // Fallback offline.
    return _service.computeVerdictOffline(
      municipality: _municipality!,
      zoneType: _zoneType,
      timePeriod: _timePeriod,
      noiseType: _noiseType,
      measuredDb: measuredDb,
    );
  }

  /// Etiqueta legible de la franja horaria actual.
  String get timePeriodLabel => _service.timePeriodLabel(_timePeriod);
}
