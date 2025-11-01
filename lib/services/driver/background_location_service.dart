import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logistics_toolkit/services/driver/background_task_handler.dart';

class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'Tracking Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      service.startService();
    }
  }

  static void stopService() {
    FlutterBackgroundService().invoke("stopService");
  }
}
