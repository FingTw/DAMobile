import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/project_details_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {

  void _showCreateProjectDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController limitController = TextEditingController(text: "10"); // Mặc định 10

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Project", style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Project Name'), autofocus: true),
              const SizedBox(height: 10),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              // Thêm ô nhập giới hạn
              TextField(controller: limitController, decoration: const InputDecoration(labelText: 'Max Members'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(child: const Text('Create'), onPressed: () {
              if (nameController.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  int max = int.tryParse(limitController.text) ?? 10;
                  DatabaseService(uid: user.uid).createProject(nameController.text, descController.text, max);
                }
                Navigator.of(context).pop();
              }
            }),
          ],
        );
      },
    );
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text("Join Project", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter the 6-character code shared by your Project Owner."),
                const SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(hintText: "e.g. A2B9X", border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                  onPressed: () async {
                    String result = await DatabaseService(uid: user.uid).joinProjectByCode(codeController.text.toUpperCase().trim());
                    if (mounted) {
                      Navigator.pop(ctx);
                      if (result == "Success") {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully joined project!"), backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text("JOIN")
              )
            ]
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Projects", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.login, color: Colors.deepPurple),
              label: const Text("Join via Code", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              onPressed: _showJoinDialog,
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: DatabaseService(uid: user.uid).getProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No projects yet.", style: GoogleFonts.poppins()));

          final projects = snapshot.data!;
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final myRole = project.members[user.uid] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: myRole == 'PO' ? Colors.orange[100] : Colors.blue[100],
                    child: Text(myRole, style: TextStyle(fontSize: 12, color: myRole == 'PO' ? Colors.orange[900] : Colors.blue[900], fontWeight: FontWeight.bold)),
                  ),
                  title: Text(project.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text(project.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsScreen(project: project)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "create_project_fab",
        onPressed: _showCreateProjectDialog,
        label: const Text("New Project"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}