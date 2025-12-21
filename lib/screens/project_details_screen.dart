import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/sprint_details_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.project.name, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.project.joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
                },
                child: Row(
                  children: [
                    Text("Code: ${widget.project.joinCode} ", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Icon(Icons.copy, size: 12, color: Colors.blue),
                  ],
                ),
              )
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.deepPurpleAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Backlog'),
              Tab(icon: Icon(Icons.run_circle_outlined), text: 'Sprints'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BacklogTab(project: widget.project),
            SprintsTab(project: widget.project),
          ],
        ),
      ),
    );
  }
}

class BacklogTab extends StatefulWidget {
  final Project project;
  const BacklogTab({super.key, required this.project});

  @override
  State<BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends State<BacklogTab> {

  void _showAddToSprintDialog(UserStory story) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add '${story.title}' to Sprint?"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<Sprint>>(
              stream: DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).getSprints(widget.project.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("No active sprints found.");

                final sprints = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: sprints.length,
                  itemBuilder: (context, index) {
                    final sprint = sprints[index];
                    return ListTile(
                      title: Text(sprint.name),
                      subtitle: Text("${DateFormat.MMMd().format(sprint.startDate)} - ${DateFormat.MMMd().format(sprint.endDate)}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid)
                            .addStoryToSprint(widget.project.id, sprint.id, story.id);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Moved to ${sprint.name}")));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop())],
        );
      },
    );
  }

  void _showAddStoryDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add User Story", style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title'), autofocus: true),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'Points'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(child: const Text('Add'), onPressed: () {
              if (titleController.text.isNotEmpty) {
                DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).addUserStory(
                    widget.project.id, titleController.text, descriptionController.text, int.tryParse(pointsController.text) ?? 0);
                Navigator.of(context).pop();
              }
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<UserStory>>(
        stream: DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).getBacklog(widget.project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Backlog is empty."));

          final stories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(story.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text("Points: ${story.points}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.input, color: Colors.blue),
                        tooltip: "Add to Sprint",
                        onPressed: () => _showAddToSprintDialog(story),
                      ),
                      CircleAvatar(radius: 15, child: Text(story.points.toString(), style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: "add_backlog_story_fab",
          onPressed: _showAddStoryDialog,
          child: const Icon(Icons.add)
      ),
    );
  }
}

class SprintsTab extends StatefulWidget {
  final Project project;
  const SprintsTab({super.key, required this.project});

  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab> {
  Future<void> _showAddSprintDialog() async {
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 14));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Create Sprint", style: GoogleFonts.poppins()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Sprint Name'), autofocus: true),
                  const SizedBox(height: 20),
                  Text("Start: ${DateFormat.yMMMd().format(startDate)}"),
                  ElevatedButton(onPressed: () async {
                    final pickedDate = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2040));
                    if (pickedDate != null) setState(() => startDate = pickedDate);
                  }, child: const Text("Select Start")),
                  const SizedBox(height: 10),
                  Text("End: ${DateFormat.yMMMd().format(endDate)}"),
                  ElevatedButton(onPressed: () async {
                    final pickedDate = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2040));
                    if (pickedDate != null) setState(() => endDate = pickedDate);
                  }, child: const Text("Select End")),
                ],
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(child: const Text('Create'), onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).addSprint(widget.project.id, nameController.text, startDate, endDate);
                    Navigator.of(context).pop();
                  }
                }),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Sprint>>(
        stream: DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).getSprints(widget.project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No sprints created yet."));
          final sprints = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sprints.length,
            itemBuilder: (context, index) {
              final sprint = sprints[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(sprint.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text("${DateFormat.yMMMd().format(sprint.startDate)} - ${DateFormat.yMMMd().format(sprint.endDate)}"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SprintDetailsScreen(project: widget.project, sprint: sprint)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: "add_sprint_fab",
          onPressed: _showAddSprintDialog,
          child: const Icon(Icons.add)
      ),
    );
  }
}