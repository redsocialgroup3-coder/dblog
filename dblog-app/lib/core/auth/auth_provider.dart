import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// ChangeNotifier que gestiona el estado de autenticación.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      _authSubscription = _authService.authStateChanges.listen((user) {
        _user = user;
        notifyListeners();
      });
      _user = _authService.currentUser;
    } catch (e) {
      log('Firebase no inicializado: $e');
    }
  }

  /// Usuario actual de Firebase.
  User? get user => _user;

  /// Si el usuario está autenticado.
  bool get isAuthenticated => _user != null;

  /// Si hay una operación de auth en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error de la última operación, o null.
  String? get errorMessage => _errorMessage;

  /// Inicia sesión con email y password.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra un nuevo usuario con email y password.
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signUpWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inicia sesión con Google.
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión con Google: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la sesión.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El email no es válido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'google-sign-in-cancelled':
        return 'Inicio de sesión con Google cancelado';
      default:
        return 'Error de autenticación: $code';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
