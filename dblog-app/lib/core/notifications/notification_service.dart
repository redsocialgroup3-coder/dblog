import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/surveillance/models/surveillance_event.dart';

/// Callback top-level para manejar tap en notificaciones en segundo plano.
@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) {
  // Se maneja en foreground vía el callback registrado en initialize().
}

/// Servicio singleton para notificaciones locales.
///
/// Configura canales Android (alta importancia) y permisos iOS.
/// Expone [showNoiseEventNotification] para mostrar notificaciones
/// al detectar un evento de ruido durante la vigilancia.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Callback que se invoca al tocar una notificación.
  /// Recibe el payload (JSON con eventId y recordingId).
  void Function(String? payload)? onNotificationTapped;

  /// ID del canal Android para eventos de vigilancia.
  static const String _channelId = 'surveillance_events';
  static const String _channelName = 'Eventos de vigilancia';
  static const String _channelDescription =
      'Notificaciones al detectar eventos de ruido durante la vigilancia';

  /// Contador incremental para IDs de notificación.
  int _notificationId = 0;

  /// Inicializa el plugin de notificaciones locales.
  ///
  /// Configura el canal Android con importancia alta y solicita
  /// permisos en iOS.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );

    // Crear canal Android de alta importancia.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    log('NotificationService: inicializado correctamente');
  }

  /// Maneja el tap del usuario en una notificación.
  void _onNotificationResponse(NotificationResponse response) {
    onNotificationTapped?.call(response.payload);
  }

  /// Muestra una notificación local para un evento de ruido detectado.
  ///
  /// El título indica que se detectó un evento y el cuerpo muestra
  /// el dB máximo y la hora de detección. El payload contiene el
  /// eventId y recordingId en formato JSON para navegación.
  Future<void> showNoiseEventNotification(SurveillanceEvent event) async {
    final hour = event.startTime.hour.toString().padLeft(2, '0');
    final minute = event.startTime.minute.toString().padLeft(2, '0');
    final dbFormatted = event.maxDb.toStringAsFixed(1);

    final payload = jsonEncode({
      'eventId': event.id,
      'recordingId': event.recordingId,
    });

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      _notificationId++,
      'Evento de ruido detectado',
      '$dbFormatted dB a las $hour:$minute',
      details,
      payload: payload,
    );
  }
}
