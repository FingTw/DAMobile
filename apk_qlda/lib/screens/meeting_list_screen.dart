import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/meeting_model.dart';
import 'create_meeting_screen.dart';

class MeetingListScreen extends StatelessWidget {
  final String sprintId;
  const MeetingListScreen({super.key, required this.sprintId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hoạt Động & Họp")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref().child('meetings').onValue.asBroadcastStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Chưa có biên bản nào."));

          Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<MeetingModel> meetings = [];

          values.forEach((key, value) {
            final data = Map<String, dynamic>.from(value);
            // LỌC theo Sprint ID
            if (data['sprint_id'] == sprintId) {
              // Xử lý list ảnh (nếu có)
              List<String> imgs = [];
              if (data['image_urls'] != null) {
                if (data['image_urls'] is List) imgs = List<String>.from(data['image_urls']);
              }

              meetings.add(MeetingModel(
                id: key,
                sprintId: data['sprint_id'],
                type: data['type'],
                content: data['content'],
                imageUrls: imgs,
                date: DateTime.fromMillisecondsSinceEpoch(data['date']),
              ));
            }
          });

          // Sort ngày mới nhất
          meetings.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              MeetingModel m = meetings[index];
              return Card(
                child: ListTile(
                  title: Text(m.type, style: TextStyle(color: m.type == 'Daily' ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.content),
                    Text("${m.date.day}/${m.date.month} ${m.date.hour}:${m.date.minute}", style: const TextStyle(fontSize: 10, color: Colors.grey))
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMeetingScreen(sprintId: sprintId))),
        child: const Icon(Icons.edit_note),
      ),
    );
  }
}