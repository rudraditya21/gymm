import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class WorkoutNotificationService {
  static const _notificationId = 1001;
  static const _channelId = 'active_workout';
  static const _activeWorkoutPayload = 'active-workout';
  static final _notifications = FlutterLocalNotificationsPlugin();
  static void Function()? _onActiveWorkoutTap;
  static var _openActiveWorkout = false;
  static var _permissionRequested = false;

  static Future<void> initialize() async {
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload == _activeWorkoutPayload) {
      _openActiveWorkout = true;
    }
  }

  static void registerTapHandler(void Function() handler) {
    _onActiveWorkoutTap = handler;
    if (_openActiveWorkout) _notifyTap();
  }

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
      payload: _activeWorkoutPayload,
    );
  }

  static Future<void> cancel() => _notifications.cancel(_notificationId);

  static Future<void> _requestPermissions() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _handleResponse(NotificationResponse response) {
    if (response.payload != _activeWorkoutPayload) return;
    _openActiveWorkout = true;
    _notifyTap();
  }

  static void _notifyTap() {
    final handler = _onActiveWorkoutTap;
    if (handler == null) return;
    _openActiveWorkout = false;
    handler();
  }
}
