import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/story_model.dart';

class AddStoryScreen extends StatefulWidget { // Bạn check lại tên class nếu muốn đổi thành CreateStoryScreen cho đồng bộ
  final String projectId;
  final StoryModel? story;

  const AddStoryScreen({super.key, required this.projectId, this.story});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  int _priority = 2;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.story != null) {
      _titleController.text = widget.story!.title;
      _descController.text = widget.story!.description;
      _pointsController.text = widget.story!.storyPoints.toString();
      _priority = widget.story!.priority;
    }
  }

  Future<void> _saveStory() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('stories');

      if (widget.story != null) {
        // --- SỬA (Update) ---
        await ref.child(widget.story!.id).update({
          'title': _titleController.text,
          'description': _descController.text,
          'story_points': int.tryParse(_pointsController.text) ?? 0,
          'priority': _priority,
        });
      } else {
        // --- THÊM (Create) ---
        DatabaseReference newRef = ref.push();
        StoryModel newStory = StoryModel(
          id: newRef.key!,
          projectId: widget.projectId,
          title: _titleController.text,
          description: _descController.text,
          storyPoints: int.tryParse(_pointsController.text) ?? 0,
          priority: _priority,
        );
        await newRef.set(newStory.toJson());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu Backlog!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Giao diện giữ nguyên, chỉ copy paste logic _saveStory ở trên)
    // Để tiết kiệm không gian, bạn dùng lại giao diện cũ, chỉ thay hàm _saveStory là được
    return Scaffold(
      appBar: AppBar(title: Text(widget.story == null ? "Thêm Yêu Cầu" : "Sửa Yêu Cầu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Tên tính năng (*)", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _pointsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Điểm (Points)", border: OutlineInputBorder()))),
            const SizedBox(width: 16),
            Expanded(child: DropdownButtonFormField<int>(value: _priority, items: const [DropdownMenuItem(value: 1, child: Text("Cao")), DropdownMenuItem(value: 2, child: Text("Trung bình")), DropdownMenuItem(value: 3, child: Text("Thấp"))], onChanged: (v) => setState(() => _priority = v!))),
          ]),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _saveStory, child: _isLoading ? const CircularProgressIndicator() : const Text("LƯU")))
        ]),
      ),
    );
  }
}