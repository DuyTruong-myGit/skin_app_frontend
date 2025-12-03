import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app/services/api_service.dart';

// [QUAN TRỌNG] Hàm này phải nằm NGOÀI class, ở cấp cao nhất (Top-level)
// Nó hoạt động kể cả khi App đã tắt
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🌙 Nhận thông báo ngầm (Background/Terminated): ${message.messageId}");
  // Tại đây bạn không cần code hiển thị thông báo,
  // vì Firebase SDK tự động hiển thị thông báo nếu payload có chứa "notification".
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Đăng ký hàm xử lý ngầm (Background Handler)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Xin quyền (iOS/Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Cấu hình Local Notification (để hiện thông báo khi app đang chạy - Foreground)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Tạo channel cho Android (Quan trọng để có âm thanh)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel', // ID trùng với Backend gửi xuống
      'Nhắc nhở thuốc',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Lắng nghe tin nhắn khi App đang MỞ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("☀️ Nhận tin nhắn Foreground: ${message.notification?.title}");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Khi app đang mở, Firebase KHÔNG tự hiện thông báo -> Phải dùng Local Notification để hiện
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Lắng nghe token thay đổi (refresh)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      ApiService().updateFcmToken(newToken);
    });
  }

  // Gọi hàm này sau khi User Login thành công
  static Future<void> syncTokenToServer() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("🔥 FCM Token hiện tại: $token");
      await ApiService().updateFcmToken(token);
    }
  }
}