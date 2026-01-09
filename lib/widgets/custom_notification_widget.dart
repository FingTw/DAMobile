import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationType { success, error, warning, info }

class CustomNotificationWidget extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onClose;

  const CustomNotificationWidget({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onClose,
  });

  // Cấu hình màu sắc và icon dựa trên Type
  Color get _bgColor {
    switch (type) {
      case NotificationType.success: return const Color(0xFFECFDF5); // Xanh lá nhạt
      case NotificationType.error: return const Color(0xFFFEF2F2);   // Đỏ nhạt
      case NotificationType.warning: return const Color(0xFFFFFBEB); // Vàng nhạt
      case NotificationType.info: return const Color(0xFFEFF6FF);    // Xanh dương nhạt
    }
  }

  Color get _borderColor {
    switch (type) {
      case NotificationType.success: return const Color(0xFF34D399);
      case NotificationType.error: return const Color(0xFFF87171);
      case NotificationType.warning: return const Color(0xFFFBBF24);
      case NotificationType.info: return const Color(0xFF60A5FA);
    }
  }

  IconData get _icon {
    switch (type) {
      case NotificationType.success: return Icons.check_circle_outline;
      case NotificationType.error: return Icons.error_outline;
      case NotificationType.warning: return Icons.warning_amber_rounded;
      case NotificationType.info: return Icons.info_outline;
    }
  }

  Color get _iconColor {
    switch (type) {
      case NotificationType.success: return const Color(0xFF059669);
      case NotificationType.error: return const Color(0xFFDC2626);
      case NotificationType.warning: return const Color(0xFFD97706);
      case NotificationType.info: return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(_icon, color: _iconColor, size: 28),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Close Button (Optional)
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 20, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}