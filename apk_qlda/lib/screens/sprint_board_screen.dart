import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sprint_model.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import 'submit_proof_screen.dart';
import 'meeting_list_screen.dart';

class SprintBoardScreen extends StatefulWidget {
  final SprintModel sprint;
  const SprintBoardScreen({super.key, required this.sprint});

  @override
  State<SprintBoardScreen> createState() => _SprintBoardScreenState();
}

class _SprintBoardScreenState extends State<SprintBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sprint.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingListScreen(sprintId: widget.sprint.id))),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "TODO"), Tab(text: "DOING"), Tab(text: "DONE")],
        ),
      ),
      // Sử dụng TabBarView chứa 3 Widget con riêng biệt (đã được KeepAlive)
      body: TabBarView(
        controller: _tabController,
        children: [
          TaskListTab(sprint: widget.sprint, statusFilter: const [1]),       // Cột Todo
          TaskListTab(sprint: widget.sprint, statusFilter: const [2]),       // Cột Doing
          TaskListTab(sprint: widget.sprint, statusFilter: const [3, 4]),    // Cột Done (Chờ duyệt + Xong)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTaskScreen(projectId: widget.sprint.projectId, sprintId: widget.sprint.id))),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- WIDGET TÁCH RIÊNG: TAB DANH SÁCH TASK (Có KeepAlive) ---
class TaskListTab extends StatefulWidget {
  final SprintModel sprint;
  final List<int> statusFilter;

  const TaskListTab({super.key, required this.sprint, required this.statusFilter});

  @override
  State<TaskListTab> createState() => _TaskListTabState();
}

class _TaskListTabState extends State<TaskListTab> with AutomaticKeepAliveClientMixin {
  // 1. Bật chế độ giữ trạng thái
  @override
  bool get wantKeepAlive => true;

  // Hàm cập nhật trạng thái (Chuyển vào đây để quản lý cục bộ)
  Future<void> _updateStatus(String taskId, int newStatus) async {
    await FirebaseDatabase.instance.ref().child('tasks').child(taskId).update({'status': newStatus});
  }

  Widget? _buildActionButtons(TaskModel task) {
    if (task.status == 1) { // Todo -> Doing
      return IconButton(icon: const Icon(Icons.play_arrow, color: Colors.blue), onPressed: () => _updateStatus(task.id, 2));
    }
    if (task.status == 2) { // Doing -> Nộp
      return IconButton(icon: const Icon(Icons.upload_file, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(task: task))));
    }
    if (task.status == 3) { // Waiting -> Duyệt
      return IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.purple, size: 30), onPressed: () {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text("Duyệt Task?"),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Git: ${task.proofGitLink ?? 'Trống'}"),
            Text("Ảnh: ${task.proofImage ?? 'Trống'}")
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(onPressed: () {Navigator.pop(ctx); _updateStatus(task.id, 4);}, child: const Text("DUYỆT"))
          ],
        ));
      });
    }
    return const Icon(Icons.check_circle, color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 2. Bắt buộc gọi super.build

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('tasks').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_outlined, size: 50, color: Colors.grey[300]), const Text("Trống", style: TextStyle(color: Colors.grey))]));
        }

        Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<TaskModel> tasks = [];

        values.forEach((key, value) {
          final data = Map<String, dynamic>.from(value);
          // LỌC: Theo Sprint ID và theo Status Filter được truyền vào
          if (data['sprint_id'] == widget.sprint.id) {
            int status = data['status'] ?? 1;
            if (widget.statusFilter.contains(status)) {
              tasks.add(TaskModel(
                id: key,
                projectId: data['project_id'],
                sprintId: data['sprint_id'],
                title: data['title'],
                content: data['content'],
                status: status,
                proofImage: data['proof_image'],
                proofGitLink: data['proof_git_link'],
                createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
              ));
            }
          }
        });

        if (tasks.isEmpty) return const Center(child: Text("Không có công việc nào"));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            TaskModel task = tasks[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(task.content, maxLines: 2),
                trailing: _buildActionButtons(task),
              ),
            );
          },
        );
      },
    );
  }
}