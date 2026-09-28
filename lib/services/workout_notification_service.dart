import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class WorkoutNotificationService {
  static const _notificationId = 1001;
  static const _channelId = 'active_workout';
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() => _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

  static Future<void> show(String workoutName) async {
    await _requestPermissions();
    await _notifications.show(
      _notificationId,
      'Workout in progress',
      '$workoutName · Timer is still running',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Active workout',
          channelDescription: 'Keeps an active workout available to resume.',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  static Future<void> cancel() => _notifications.cancel(_notificationId);

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
