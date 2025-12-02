import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. CHÌA KHÓA VẠN NĂNG (GlobalKey)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- CẤU HÌNH ---
final String oneSignalAppId = "03c2ac46-27d6-4ec2-aa77-fe52e1b37fb2";
final String oneSignalRestApiKey = "os_v2_app_apbkyrrh2zhmfktx7zjodm37wiqoyyrkrasuy657jky4zfcs33b54sqge63mokps6b6r36z7fe6vjusqpuytx3vzjch6bqnf6jc4pca";

// 2. HÀM KHỞI TẠO ONESIGNAL (Chạy độc lập ngay khi App mở)
Future<void> initOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);

  // --- LẮNG NGHE SỰ KIỆN TOÀN CỤC ---
  OneSignal.Notifications.addClickListener((event) async {
    print("🔔 GLOBAL LISTENER: Đã bắt được sự kiện click!");

    var data = event.notification.additionalData;

    if (data != null && data['action'] == 'mo_chi_tiet') {
      print("🚀 Đang điều hướng...");

      // Chờ 1 chút xíu để đảm bảo Navigator đã sẵn sàng
      await Future.delayed(Duration(milliseconds: 500));

      // Dùng chìa khóa vạn năng để đẩy màn hình mới vào bất kể đang ở đâu
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => OrderDetailPage()),
      );
    }
  });
}

void main() async {
  // Đảm bảo Flutter Binding đã tải xong trước khi làm gì khác
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi động OneSignal ngay lập tức
  await initOneSignal();

  runApp(MaterialApp(
    navigatorKey: navigatorKey, // Gắn chìa khóa vào App
    debugShowCheckedModeBanner: false,
    home: ShopPage(),
  ));
}

class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // --- Hàm gửi thông báo (Backend giả lập) ---
  Future<void> handleCheckout() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => Center(child: CircularProgressIndicator())
    );

    await Future.delayed(Duration(seconds: 1));
    Navigator.pop(context);

    await sendPushNotification(
      title: "✅ Đặt hàng thành công!",
      content: "Chạm vào đây để xem chi tiết đơn hàng #12345.",
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Đã gửi thông báo"),
        content: Text("Bây giờ hãy THOÁT APP ra màn hình chính và bấm vào thông báo."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  Future<void> sendPushNotification({required String title, required String content}) async {
    var headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Basic $oneSignalRestApiKey',
    };

    var body = jsonEncode({
      "app_id": oneSignalAppId,
      "included_segments": ["Total Subscriptions"],
      "headings": {"en": title},
      "contents": {"en": content},
      // DỮ LIỆU ĐIỀU HƯỚNG
      "data": {
        "action": "mo_chi_tiet",
        "order_id": "12345"
      }
    });

    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: headers,
        body: body,
      );
      print("Đã gửi lệnh push!");
    } catch (e) {
      print("Lỗi: $e");
    }
  }

  void handleAddToCart() {
    OneSignal.InAppMessages.addTrigger("hanh_dong", "them_gio_hang");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm vào giỏ!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shop Global Fix"), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 250, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage("https://images.pexels.com/photos/1070360/pexels-photo-1070360.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Nike Air Jordan 1", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(Icons.add_shopping_cart), label: Text("THÊM VÀO GIỎ"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 15)), onPressed: handleAddToCart)),
            SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(Icons.payment), label: Text("THANH TOÁN & TEST PUSH"), style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 15)), onPressed: handleCheckout)),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH CHI TIẾT ---
class OrderDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Chi Tiết Đơn Hàng"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text("THÀNH CÔNG!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
            Text("Bạn đã điều hướng thành công.", textAlign: TextAlign.center),
            SizedBox(height: 30),
            ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text("Về trang chủ")
            )
          ],
        ),
      ),
    );
  }
}