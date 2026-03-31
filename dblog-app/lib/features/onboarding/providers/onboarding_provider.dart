import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que gestiona el estado del flujo de onboarding.
class OnboardingProvider extends ChangeNotifier {
  static const String _completedKey = 'onboarding_completed';
  static const String _addressKey = 'onboarding_address';
  static const String _floorKey = 'onboarding_floor';
  static const String _cityKey = 'onboarding_city';

  int _currentPage = 0;
  bool _completed = false;
  bool _loading = true;

  // Estado de permisos.
  bool _microphoneGranted = false;
  bool _locationGranted = false;
  bool _notificationsGranted = false;

  // Dirección del inmueble.
  String _address = '';
  String _floor = '';
  String _city = '';

  int get currentPage => _currentPage;
  bool get completed => _completed;
  bool get loading => _loading;
  bool get microphoneGranted => _microphoneGranted;
  bool get locationGranted => _locationGranted;
  bool get notificationsGranted => _notificationsGranted;
  String get address => _address;
  String get floor => _floor;
  String get city => _city;

  /// Número total de páginas del onboarding.
  static const int totalPages = 5;

  OnboardingProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_completedKey) ?? false;
    _address = prefs.getString(_addressKey) ?? '';
    _floor = prefs.getString(_floorKey) ?? '';
    _city = prefs.getString(_cityKey) ?? '';
    _loading = false;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  void setMicrophoneGranted(bool value) {
    _microphoneGranted = value;
    notifyListeners();
  }

  void setLocationGranted(bool value) {
    _locationGranted = value;
    notifyListeners();
  }

  void setNotificationsGranted(bool value) {
    _notificationsGranted = value;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
  }

  void setFloor(String value) {
    _floor = value;
  }

  void setCity(String value) {
    _city = value;
  }

  /// Completa el onboarding y persiste el estado.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    if (_address.isNotEmpty) {
      await prefs.setString(_addressKey, _address);
    }
    if (_floor.isNotEmpty) {
      await prefs.setString(_floorKey, _floor);
    }
    if (_city.isNotEmpty) {
      await prefs.setString(_cityKey, _city);
    }
    _completed = true;
    notifyListeners();
  }

  /// Salta el onboarding sin guardar dirección.
  Future<void> skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    _completed = true;
    notifyListeners();
  }
}
