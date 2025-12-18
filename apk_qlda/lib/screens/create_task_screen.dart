import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  final String sprintId;
  final TaskModel? task;

  const CreateTaskScreen({super.key, required this.projectId, required this.sprintId, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _contentController.text = widget.task!.content;
    }
  }

  Future<void> _saveTask() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('tasks');

      if (widget.task != null) {
        // --- SỬA ---
        await ref.child(widget.task!.id).update({
          'title': _titleController.text,
          'content': _contentController.text,
        });
      } else {
        // --- THÊM ---
        DatabaseReference newRef = ref.push();
        TaskModel newTask = TaskModel(
          id: newRef.key!,
          projectId: widget.projectId,
          sprintId: widget.sprintId,
          title: _titleController.text,
          content: _contentController.text,
          status: 1, // Todo
          createdAt: DateTime.now(),
        );
        await newRef.set(newTask.toJson());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu công việc!')));
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
      appBar: AppBar(title: Text(widget.task == null ? "Tạo Task" : "Sửa Task")),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Tên công việc (*)", border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _contentController, decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _saveTask, child: _isLoading ? const CircularProgressIndicator() : const Text("LƯU")))
      ])),
    );
  }
}