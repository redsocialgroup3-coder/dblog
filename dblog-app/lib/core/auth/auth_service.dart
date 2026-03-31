import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio que encapsula Firebase Auth.
///
/// NOTA: Requiere configuración de Firebase (google-services.json para Android,
/// GoogleService-Info.plist para iOS). Sin estos archivos, Firebase no se
/// inicializará y los métodos lanzarán excepciones controladas.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Stream de cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuario actual, o null si no hay sesión.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Registra un nuevo usuario con email y password.
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      log('Error en signUpWithEmail: ${e.code}');
      rethrow;
    }
  }

  /// Inicia sesión con email y password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      log('Error en signInWithEmail: ${e.code}');
      rethrow;
    }
  }

  /// Inicia sesión con Google Sign-In.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw AuthCancelledException('El usuario canceló el inicio de sesión con Google');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Placeholder para Apple Sign-In (pendiente de implementar).
  Future<UserCredential> signInWithApple() async {
    // TODO: Implementar Apple Sign-In
    throw UnimplementedError('Apple Sign-In aún no está implementado');
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }

  /// Obtiene el ID token del usuario actual para enviar al backend.
  Future<String?> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken();
  }
}

/// Excepción cuando el usuario cancela el flujo de autenticación.
class AuthCancelledException implements Exception {
  final String message;

  AuthCancelledException(this.message);

  @override
  String toString() => 'AuthCancelledException: $message';
}
