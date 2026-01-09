import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:untitled3/services/toast_service.dart'; // Import Toast
import 'package:untitled3/widgets/custom_notification_widget.dart'; // Import Enum Type

class NotificationService {
  static const String oneSignalAppId = "6ac28531-232a-43aa-a960-d1114cab6c8a";

  static Future<void> initOneSignal() async {
    // 1. Log để debug (Tắt khi release)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // 2. Khởi tạo
    OneSignal.initialize(oneSignalAppId);

    // 3. Xin quyền thông báo
    OneSignal.Notifications.requestPermission(true);

    // 4. LẤY ID THIẾT BỊ ĐỂ TEST (Quan trọng)
    // Bạn cần ID này để dán vào trang web OneSignal khi test gửi
    var id = OneSignal.User.pushSubscription.id;
    print("OneSignal Player ID: $id");

    // Lắng nghe nếu ID thay đổi (do mạng chậm lúc đầu chưa có)
    OneSignal.User.pushSubscription.addObserver((state) {
      print("OneSignal Player ID update: ${state.current.id}");
    });

    // 5. XỬ LÝ KHI APP ĐANG MỞ (Foreground) - Phần này code cũ của bạn thiếu
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Chặn thông báo hệ thống mặc định (để không bị rung/kêu ting ting vô duyên khi đang dùng app)
      event.preventDefault();

      // Hiển thị cái Toast đẹp của mình
      // Vì ToastService đã dùng GlobalKey nên gọi ở đây thoải mái không cần context
      print(">>> Đang gọi ToastService...");
      ToastService.show(
        title: event.notification.title ?? "Thông báo",
        message: event.notification.body ?? "",
        type: NotificationType.info, // Mặc định là Info, bạn có thể gửi data từ server để đổi màu
      );
    });

    // 6. Xử lý khi bấm vào thông báo (Giữ nguyên như bạn làm)
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: ${event.notification.additionalData}');
      // Logic điều hướng (Navigate) sẽ viết ở đây
    });
  }
}