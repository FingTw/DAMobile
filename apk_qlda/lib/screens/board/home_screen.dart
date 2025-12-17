import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _testRef = FirebaseDatabase.instance.ref("test_connection");

  String _status = "Đang chờ...";

  // Hàm test ghi dữ liệu lên Firebase
  void _testWriteData() async {
    try {
      await _testRef.set({
        "message": "Hello from Flutter!",
        "timestamp": DateTime.now().toIso8601String(),
        "user": "Test User"
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã ghi thành công lên Firebase!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scrum Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Trạng thái kết nối Firebase:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            // Lắng nghe dữ liệu real-time để xem có đọc được không
            StreamBuilder(
              stream: _testRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map;
                  return Text(
                    "Data từ DB:\n${data['message']}\n(${data['timestamp']})",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  );
                } else if (snapshot.hasError) {
                  return Text("Lỗi đọc: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                }
                return const Text("Chưa có dữ liệu", style: TextStyle(color: Colors.grey));
              },
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _testWriteData,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Test Ghi Database"),
            ),
          ],
        ),
      ),
    );
  }
}