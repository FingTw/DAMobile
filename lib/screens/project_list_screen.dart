
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/project_details_screen.dart'; // Import the details screen

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {

  void _showCreateProjectDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

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
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(child: const Text('Create'), onPressed: () {
              if (nameController.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  DatabaseService(uid: user.uid).createProject(nameController.text, descController.text);
                }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Projects", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Project>>(
        stream: DatabaseService(uid: user.uid).getProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("You are not in any projects yet.", style: GoogleFonts.poppins()),
            );
          }

          final projects = snapshot.data!;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(project.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text(project.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProjectDetailsScreen(project: project)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        label: const Text("New Project"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
