import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Thư viện Realtime DB
import '../models/project_model.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now().add(const Duration(days: 14))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên dự án')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- REALTIME DB: Tạo ID mới bằng push() ---
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('projects');
      DatabaseReference newRef = ref.push();

      ProjectModel newProject = ProjectModel(
        id: newRef.key!, // Lấy ID vừa tạo
        name: _nameController.text,
        description: _descController.text,
        startDate: _startDate,
        endDate: _endDate,
        managerId: "TEST_MANAGER_ID",
        memberIds: ["TEST_MANAGER_ID"],
      );

      // set dữ liệu (toJson đã chuyển ngày tháng thành số)
      await newRef.set(newProject.toJson());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo dự án thành công!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Phần giao diện giữ nguyên như cũ, chỉ thay logic save)
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo Dự Án (Realtime)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Tên Dự Án (*)", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: InkWell(onTap: () => _selectDate(context, true), child: InputDecorator(decoration: const InputDecoration(labelText: "Ngày Bắt Đầu", border: OutlineInputBorder()), child: Text("${_startDate.day}/${_startDate.month}/${_startDate.year}")))),
              const SizedBox(width: 16),
              Expanded(child: InkWell(onTap: () => _selectDate(context, false), child: InputDecorator(decoration: const InputDecoration(labelText: "Ngày Kết Thúc", border: OutlineInputBorder()), child: Text(_endDate == null ? "Chọn ngày" : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}")))),
            ]),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _saveProject, child: _isLoading ? const CircularProgressIndicator() : const Text("KHỞI TẠO DỰ ÁN"))),
          ],
        ),
      ),
    );
  }
}