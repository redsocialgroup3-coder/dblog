import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_service.dart';
import 'sync_service.dart';

/// Provider que gestiona el estado de sincronización.
/// Detecta conectividad y ejecuta sync automático cuando hay conexión.
class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  int _pendingUploads = 0;
  int get pendingUploads => _pendingUploads;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncProvider() {
    _init();
  }

  Future<void> _init() async {
    // Cargar estado inicial.
    _lastSyncTime = await _syncService.getLastSyncTime();
    await _updatePendingCount();

    // Escuchar cambios de conectividad.
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Verificar conectividad actual.
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    final wasOffline = !_isOnline;
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();

    // Auto-sync al recuperar conexión si hay pendientes y usuario autenticado.
    if (wasOffline && _isOnline && _pendingUploads > 0) {
      _autoSync();
    }
  }

  Future<void> _autoSync() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await syncAll();
  }

  /// Ejecuta sincronización completa.
  Future<void> syncAll() async {
    if (_isSyncing) return;

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _errorMessage = 'Debes iniciar sesión para sincronizar';
      notifyListeners();
      return;
    }

    if (!_isOnline) {
      _errorMessage = 'Sin conexión a internet';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _syncService.syncAll();
      if (success) {
        _lastSyncTime = DateTime.now();
      } else {
        _errorMessage = 'Error durante la sincronización';
      }
    } catch (e) {
      _errorMessage = 'Error de sincronización: $e';
      debugPrint('SyncProvider: error en syncAll: $e');
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
      notifyListeners();
    }
  }

  /// Agrega un recording a la cola de pendientes.
  Future<void> addToPendingQueue(String recordingId) async {
    await _syncService.addToPendingQueue(recordingId);
    await _updatePendingCount();
    notifyListeners();
  }

  Future<void> _updatePendingCount() async {
    final pending = await _syncService.getPendingIds();
    _pendingUploads = pending.length;
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
