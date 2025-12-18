import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/meeting_model.dart';

class CreateMeetingScreen extends StatefulWidget {
  final String sprintId;
  const CreateMeetingScreen({super.key, required this.sprintId});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _contentController = TextEditingController();
  String _type = 'Daily';
  bool _isLoading = false;

  Future<void> _saveMeeting() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_contentController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('meetings');
      DatabaseReference newRef = ref.push();

      MeetingModel newMeeting = MeetingModel(
        id: newRef.key!,
        sprintId: widget.sprintId,
        type: _type,
        content: _contentController.text,
        imageUrls: [],
        date: DateTime.now(),
      );

      await newRef.set(newMeeting.toJson());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu biên bản!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo Biên Bản Họp")),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        DropdownButtonFormField<String>(value: _type, items: const [DropdownMenuItem(value: 'Daily', child: Text("Daily Scrum")), DropdownMenuItem(value: 'Review', child: Text("Sprint Review"))], onChanged: (v) => setState(() => _type = v!)),
        const SizedBox(height: 16),
        TextField(controller: _contentController, decoration: const InputDecoration(labelText: "Nội dung", border: OutlineInputBorder()), maxLines: 8),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _saveMeeting, child: _isLoading ? const CircularProgressIndicator() : const Text("LƯU")))
      ])),
    );
  }
}