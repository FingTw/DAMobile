import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/project_model.dart';
import 'screens/create_project_screen.dart';
import 'screens/project_detail_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scrum Realtime',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh Sách Dự Án")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref().child('projects').onValue.asBroadcastStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Chưa có dự án nào. Hãy tạo mới!"));
          }

          Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<ProjectModel> projects = [];

          values.forEach((key, value) {
            final data = Map<String, dynamic>.from(value);

            // --- Xử lý danh sách thành viên an toàn ---
            List<String> members = [];
            if (data['member_ids'] != null) {
              if (data['member_ids'] is List) {
                members = List<String>.from(data['member_ids']);
              } else if (data['member_ids'] is Map) {
                members = List<String>.from((data['member_ids'] as Map).values);
              }
            }
            // ------------------------------------------

            projects.add(ProjectModel(
              id: key,
              name: data['name'] ?? 'No Name',
              description: data['description'] ?? '',
              startDate: DateTime.fromMillisecondsSinceEpoch(data['start_date'] ?? DateTime.now().millisecondsSinceEpoch),
              endDate: data['end_date'] != null ? DateTime.fromMillisecondsSinceEpoch(data['end_date']) : null,
              // --- ĐÃ BỔ SUNG 2 TRƯỜNG CÒN THIẾU ---
              managerId: data['manager_id'] ?? 'Admin',
              memberIds: members,
            ));
          });

          // Sắp xếp dự án mới nhất lên đầu
          projects.sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(child: const Icon(Icons.business), backgroundColor: Colors.blue.shade100),
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Bắt đầu: ${project.startDate.day}/${project.startDate.month}/${project.startDate.year}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: project)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateProjectScreen())),
        label: const Text("Tạo Dự Án"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}