import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class SubmitProofScreen extends StatefulWidget {
  final TaskModel task;
  const SubmitProofScreen({super.key, required this.task});

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  final _gitController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitProof() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_gitController.text.isEmpty && _imageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập ít nhất một minh chứng!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Cập nhật lên Realtime DB
      await FirebaseDatabase.instance.ref().child('tasks').child(widget.task.id).update({
        'proof_git_link': _gitController.text,
        'proof_image': _imageController.text,
        'status': 3, // Chuyển sang Waiting Approval
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nộp!')));
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
      appBar: AppBar(title: const Text("Nộp Minh Chứng")),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text("Task: ${widget.task.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _gitController, decoration: const InputDecoration(labelText: "Link Github", border: OutlineInputBorder(), prefixIcon: Icon(Icons.code))),
        const SizedBox(height: 16),
        TextField(controller: _imageController, decoration: const InputDecoration(labelText: "Link Ảnh", border: OutlineInputBorder(), prefixIcon: Icon(Icons.image))),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submitProof, child: _isLoading ? const CircularProgressIndicator() : const Text("GỬI DUYỆT")))
      ])),
    );
  }
}