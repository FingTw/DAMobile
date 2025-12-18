import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/project_model.dart';
import '../models/story_model.dart';
import '../models/sprint_model.dart';
import 'create_story_screen.dart'; // Kiểm tra lại tên file create_story_screen hoặc add_story_screen
import 'create_sprint_screen.dart';
import 'sprint_board_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "BACKLOG", icon: Icon(Icons.list)),
            Tab(text: "SPRINTS", icon: Icon(Icons.directions_run)),
          ],
        ),
      ),
      // Sử dụng TabBarView để chứa 2 màn hình con
      body: TabBarView(
        controller: _tabController,
        children: [
          // Gọi Widget BacklogTab đã tách riêng ở dưới
          BacklogTab(projectId: widget.project.id),
          // Gọi Widget SprintsTab đã tách riêng ở dưới
          SprintsTab(projectId: widget.project.id),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddStoryScreen(projectId: widget.project.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CreateSprintScreen(projectId: widget.project.id)));
          }
        },
      ),
    );
  }
}

// --- WIDGET 1: TAB BACKLOG (Có chức năng KeepAlive) ---
class BacklogTab extends StatefulWidget {
  final String projectId;
  const BacklogTab({super.key, required this.projectId});

  @override
  State<BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends State<BacklogTab> with AutomaticKeepAliveClientMixin {
  // Bắt buộc có dòng này để giữ trạng thái khi chuyển tab
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc gọi super.build

    return StreamBuilder<DatabaseEvent>(
      // LƯU Ý: Ở đây ta bỏ .asBroadcastStream() đi cũng được vì KeepAlive đã giữ kết nối rồi
      // Nhưng để an toàn cứ dùng onValue thường, nó sẽ tự fetch lại data mới nhất khi cần
      stream: FirebaseDatabase.instance.ref().child('stories').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Backlog trống."));

        Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<StoryModel> stories = [];

        values.forEach((key, value) {
          final data = Map<String, dynamic>.from(value);
          if (data['project_id'] == widget.projectId) {
            stories.add(StoryModel(
              id: key,
              projectId: data['project_id'],
              title: data['title'],
              description: data['description'],
              storyPoints: data['story_points'],
              priority: data['priority'],
            ));
          }
        });

        if (stories.isEmpty) return const Center(child: Text("Chưa có yêu cầu nào."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text("${story.storyPoints}")),
                title: Text(story.title),
                subtitle: Text("Priority: ${story.priority}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    FirebaseDatabase.instance.ref().child('stories').child(story.id).remove();
                  },
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddStoryScreen(projectId: widget.projectId, story: story))),
              ),
            );
          },
        );
      },
    );
  }
}

// --- WIDGET 2: TAB SPRINTS (Có chức năng KeepAlive) ---
class SprintsTab extends StatefulWidget {
  final String projectId;
  const SprintsTab({super.key, required this.projectId});

  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateSprintScreen(projectId: widget.projectId))),
            icon: const Icon(Icons.add),
            label: const Text("TẠO SPRINT MỚI"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref().child('sprints').onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Chưa có Sprint nào."));

              Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<SprintModel> sprints = [];

              values.forEach((key, value) {
                final data = Map<String, dynamic>.from(value);
                if (data['project_id'] == widget.projectId) {
                  sprints.add(SprintModel(
                    id: key,
                    projectId: data['project_id'],
                    name: data['name'],
                    startDate: DateTime.fromMillisecondsSinceEpoch(data['start_date']),
                    endDate: DateTime.fromMillisecondsSinceEpoch(data['end_date']),
                    isCompleted: data['is_completed'],
                  ));
                }
              });

              sprints.sort((a, b) => b.startDate.compareTo(a.startDate));

              return ListView.builder(
                itemCount: sprints.length,
                itemBuilder: (context, index) {
                  final sprint = sprints[index];
                  return Card(
                    color: Colors.blue.shade50,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(sprint.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${sprint.startDate.day}/${sprint.startDate.month} - ${sprint.endDate.day}/${sprint.endDate.month}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SprintBoardScreen(sprint: sprint))),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}