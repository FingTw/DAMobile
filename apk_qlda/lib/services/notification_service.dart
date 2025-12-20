import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // App ID lấy từ file cũ của bạn
  static const String oneSignalAppId = "03c2ac46-27d6-4ec2-aa77-fe52e1b37fb2";

  static Future<void> initialize() async {
    // 1. Set Log level để debug
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // 2. Khởi tạo SDK
    OneSignal.initialize(oneSignalAppId);

    // 3. Xin quyền thông báo (Quan trọng cho iOS/Android 13+)
    OneSignal.Notifications.requestPermission(true);

    // 4. Lắng nghe khi người dùng click vào thông báo
    OneSignal.Notifications.addClickListener((event) {
      print("🔔 Đã click vào thông báo: ${event.notification.title}");
      // Logic điều hướng sẽ xử lý sau tùy vào màn hình
    });
  }
}