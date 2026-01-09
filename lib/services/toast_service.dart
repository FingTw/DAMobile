import 'package:flutter/material.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';
import 'package:untitled3/main.dart';

class ToastService {
  // Bỏ tham số context đi
  static void show({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dùng key để lấy state hiện tại
    final state = scaffoldMessengerKey.currentState;

    if (state != null) {
      // Ẩn thông báo cũ
      state.removeCurrentSnackBar();

      // Hiện thông báo mới
      state.showSnackBar(
        SnackBar(
          content: CustomNotificationWidget(
            title: title,
            message: message,
            type: type,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
    }
  }
}