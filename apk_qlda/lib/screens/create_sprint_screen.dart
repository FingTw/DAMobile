import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sprint_model.dart';

class CreateSprintScreen extends StatefulWidget {
  final String projectId;
  const CreateSprintScreen({super.key, required this.projectId});

  @override
  State<CreateSprintScreen> createState() => _CreateSprintScreenState();
}

class _CreateSprintScreenState extends State<CreateSprintScreen> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked; else _endDate = picked;
      });
    }
  }

  Future<void> _saveSprint() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('sprints');
      DatabaseReference newRef = ref.push();

      SprintModel newSprint = SprintModel(
        id: newRef.key!,
        projectId: widget.projectId,
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        isCompleted: false,
      );

      await newRef.set(newSprint.toJson());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo Sprint!')));
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
      appBar: AppBar(title: const Text("Tạo Sprint")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Tên Sprint", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: InkWell(onTap: () => _selectDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: "Bắt đầu", border: OutlineInputBorder()), child: Text("${_startDate.day}/${_startDate.month}/${_startDate.year}")))),
            const SizedBox(width: 10),
            Expanded(child: InkWell(onTap: () => _selectDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: "Kết thúc", border: OutlineInputBorder()), child: Text("${_endDate.day}/${_endDate.month}/${_endDate.year}")))),
          ]),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _saveSprint, child: _isLoading ? const CircularProgressIndicator() : const Text("LƯU SPRINT"))),
        ]),
      ),
    );
  }
}