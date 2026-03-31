import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_service.dart';
import '../models/user_profile.dart';

/// ChangeNotifier que gestiona el perfil del usuario.
///
/// Carga el perfil del backend si el usuario esta autenticado,
/// o de shared_preferences si esta offline.
class ProfileProvider extends ChangeNotifier {
  static const String _displayNameKey = 'profile_display_name';
  static const String _addressKey = 'profile_address';
  static const String _floorDoorKey = 'profile_floor_door';
  static const String _municipalityKey = 'profile_municipality';
  static const String _calibrationOffsetKey = 'profile_calibration_offset';
  static const String _dbThresholdKey = 'profile_db_threshold';

  final ApiService _api = ApiService.instance;

  UserProfile _profile = UserProfile();
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Campos individuales para facilitar el acceso.
  String? get displayName => _profile.displayName;
  String? get email => _profile.email;
  String? get address => _profile.address;
  String? get floorDoor => _profile.floorDoor;
  String? get municipality => _profile.municipality;
  double get calibrationOffset => _profile.calibrationOffset;
  double get dbThreshold => _profile.dbThreshold;

  ProfileProvider() {
    _loadFromLocal();
  }

  /// Carga el perfil desde shared_preferences (datos locales).
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _profile = UserProfile(
      displayName: prefs.getString(_displayNameKey),
      address: prefs.getString(_addressKey),
      floorDoor: prefs.getString(_floorDoorKey),
      municipality: prefs.getString(_municipalityKey),
      calibrationOffset: prefs.getDouble(_calibrationOffsetKey) ?? 0.0,
      dbThreshold: prefs.getDouble(_dbThresholdKey) ?? 65.0,
    );
    notifyListeners();
  }

  /// Guarda el perfil en shared_preferences.
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_profile.displayName != null) {
      await prefs.setString(_displayNameKey, _profile.displayName!);
    }
    if (_profile.address != null) {
      await prefs.setString(_addressKey, _profile.address!);
    }
    if (_profile.floorDoor != null) {
      await prefs.setString(_floorDoorKey, _profile.floorDoor!);
    }
    if (_profile.municipality != null) {
      await prefs.setString(_municipalityKey, _profile.municipality!);
    }
    await prefs.setDouble(_calibrationOffsetKey, _profile.calibrationOffset);
    await prefs.setDouble(_dbThresholdKey, _profile.dbThreshold);
  }

  /// Carga el perfil desde el backend.
  Future<void> loadFromBackend() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final json = await _api.get('/users/me/profile');
      _profile = UserProfile.fromJson(json);
      await _saveToLocal();
    } on ApiException catch (e) {
      log('Error cargando perfil: $e');
      _errorMessage = e.message;
    } catch (e) {
      log('Error cargando perfil: $e');
      _errorMessage = 'No se pudo cargar el perfil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el perfil en el backend y localmente.
  Future<bool> updateProfile({
    String? displayName,
    String? address,
    String? floorDoor,
    String? municipality,
    double? calibrationOffset,
    double? dbThreshold,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (address != null) updates['address'] = address;
    if (floorDoor != null) updates['floor_door'] = floorDoor;
    if (municipality != null) updates['municipality'] = municipality;
    if (calibrationOffset != null) {
      updates['calibration_offset'] = calibrationOffset;
    }
    if (dbThreshold != null) updates['db_threshold'] = dbThreshold;

    try {
      final json = await _api.put('/users/me/profile', body: updates);
      _profile = UserProfile.fromJson(json);
      await _saveToLocal();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      log('Error actualizando perfil: $e');
      // Guardar localmente igualmente.
      _profile = _profile.copyWith(
        displayName: displayName ?? _profile.displayName,
        address: address ?? _profile.address,
        floorDoor: floorDoor ?? _profile.floorDoor,
        municipality: municipality ?? _profile.municipality,
        calibrationOffset: calibrationOffset ?? _profile.calibrationOffset,
        dbThreshold: dbThreshold ?? _profile.dbThreshold,
      );
      await _saveToLocal();
      _errorMessage = 'Guardado localmente. ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      log('Error actualizando perfil: $e');
      // Guardar localmente igualmente.
      _profile = _profile.copyWith(
        displayName: displayName ?? _profile.displayName,
        address: address ?? _profile.address,
        floorDoor: floorDoor ?? _profile.floorDoor,
        municipality: municipality ?? _profile.municipality,
        calibrationOffset: calibrationOffset ?? _profile.calibrationOffset,
        dbThreshold: dbThreshold ?? _profile.dbThreshold,
      );
      await _saveToLocal();
      _errorMessage = 'Guardado localmente. Sin conexion al servidor.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina la cuenta del usuario en el backend.
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/users/me');
      // Limpiar datos locales.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_displayNameKey);
      await prefs.remove(_addressKey);
      await prefs.remove(_floorDoorKey);
      await prefs.remove(_municipalityKey);
      await prefs.remove(_calibrationOffsetKey);
      await prefs.remove(_dbThresholdKey);
      _profile = UserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar la cuenta';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
