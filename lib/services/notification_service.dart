import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Xử lý khi bấm vào thông báo
        print("User clicked notification: ${details.payload}");
      },
    );

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // Yêu cầu quyền đặt lịch chính xác (cho Android 12+)
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required List<int> days,
  }) async {
    // Xóa lịch cũ trước khi đặt mới
    await cancelNotification(id);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'medication_channel', // ID kênh
      'Nhắc nhở thuốc & Lịch trình', // Tên kênh
      channelDescription: 'Thông báo nhắc nhở lịch trình hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true, // Quan trọng: Đánh thức màn hình
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    for (int day in days) {
      // Chuyển đổi: App (2=T2...8=CN) -> DateTime (1=T2...7=CN)
      int dartDay = day == 8 ? 7 : day - 1;

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id * 10 + day, // Tạo ID duy nhất cho mỗi ngày
          title,
          body,
          _nextInstanceOfDayAndTime(dartDay, time),
          platformChannelSpecifics,
          // Yêu cầu phiên bản flutter_local_notifications >= 16.0.0
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        // Đã xóa đoạn log dùng NavigationService gây lỗi
        print("Đã đặt lịch (ID gốc: $id) vào thứ $day lúc ${time.hour}:${time.minute}");

      } catch (e) {
        print("Lỗi đặt lịch: $e");
      }
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, TimeOfDay time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }


  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // HÀM MỚI: Đặt lịch 1 lần vào ngày cụ thể
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date, // Ngày giờ cụ thể (Đã bao gồm TimeOfDay)
  }) async {
    // Xóa ID cũ (nếu chuyển từ lặp lại sang 1 lần)
    await cancelNotification(id);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_channel', 'Nhắc nhở',
      importance: Importance.max, priority: Priority.high,
      fullScreenIntent: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id * 10, // ID quy ước cho one-time (hoặc giữ id gốc cũng được vì chỉ chạy 1 lần)
        title,
        body,
        tz.TZDateTime.from(date, tz.local), // Thời gian cụ thể
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // KHÔNG CÓ matchDateTimeComponents => Chỉ báo 1 lần
      );
      print("Đã đặt lịch 1 lần vào $date");
    } catch (e) {
      print("Lỗi đặt lịch OneTime: $e");
    }
  }

  // HÀM HỦY (Cập nhật để hủy triệt để)
  Future<void> cancelNotification(int id) async {
    // Hủy các lịch lặp (ID * 10 + 2..8)
    for (int i = 2; i <= 8; i++) {
      await flutterLocalNotificationsPlugin.cancel(id * 10 + i);
    }
    // Hủy lịch OneTime (ID * 10)
    await flutterLocalNotificationsPlugin.cancel(id * 10);
  }


}