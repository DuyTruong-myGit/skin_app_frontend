import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/notification_service.dart'; // <--- Import file này

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🌙 Nhận thông báo ngầm: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Đăng ký background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Xin quyền
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // --- ĐÃ XÓA PHẦN KHỞI TẠO LOCAL NOTIFICATIONS THỪA THÃI ---
    // (Vì NotificationService.init() ở main.dart đã làm việc này rồi)

    // 3. Lắng nghe Foreground (Khi app đang mở)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("☀️ Nhận tin nhắn Foreground: ${message.notification?.title}");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // ==> GỌI QUA NOTIFICATION SERVICE ĐỂ HIỂN THỊ
        NotificationService().showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: 'schedule_reminder',
        );
      }
    });

    // 4. Token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      ApiService().updateFcmToken(newToken);
    });
  }

  static Future<void> syncTokenToServer() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("🔥 FCM Token: $token");
      await ApiService().updateFcmToken(token);
    }
  }
}