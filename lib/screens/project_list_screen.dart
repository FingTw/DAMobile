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
    final TextEditingController limitController = TextEditingController(
      text: "10",
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tạo không gian", // Create Workspace
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên không gian *',
                    labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (Tùy chọn)',
                    labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Only show technical fields if necessary, user screenshots show simple form
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Hủy',
                        style: GoogleFonts.inter(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Minimalist
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            int max = int.tryParse(limitController.text) ?? 10;
                            DatabaseService(uid: user.uid).createProject(
                              nameController.text,
                              descController.text,
                              max,
                            );
                          }
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'Tạo',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Join Dialog
  void _showJoinDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tham gia không gian",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Mã không gian',
                    labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Hủy',
                        style: GoogleFonts.inter(color: Colors.grey[700]),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () async {
                        if (codeController.text.isNotEmpty) {
                          String res = await DatabaseService(
                            uid: FirebaseAuth.instance.currentUser?.uid,
                          ).joinProjectByCode(codeController.text);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(res)));
                          }
                        }
                      },
                      child: Text(
                        'Tham gia',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        title: Text(
          "Không gian",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E1E1E),
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.black87, size: 28),
            onSelected: (value) {
              if (value == 'create') _showCreateProjectDialog();
              if (value == 'join') _showJoinDialog();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'create',
                child: Text('Tạo không gian mới', style: GoogleFonts.inter()),
              ),
              PopupMenuItem<String>(
                value: 'join',
                child: Text('Tham gia không gian', style: GoogleFonts.inter()),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: DatabaseService(uid: user.uid).getProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final projects = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar similar to screenshots
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF3F4F6,
                    ), // Light grey input background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm không gian",
                      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "Đã xem gần đây",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: projects.length,
                  separatorBuilder: (c, i) =>
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProjectDetailsScreen(project: project),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getProjectColor(
                                  index,
                                ), // Random or deterministic neutral/pastel color
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: _getProjectIcon(index)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    project.description.isEmpty
                                        ? "SCRUM board"
                                        : project.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.star_border, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProjectColor(int index) {
    final colors = [
      const Color(0xFFE0F2F1), // Teal 50
      const Color(0xFFFFEBEE), // Red 50
      const Color(0xFFE3F2FD), // Blue 50
      const Color(0xFFF3E5F5), // Purple 50
      const Color(0xFFFFF3E0), // Orange 50
    ];
    return colors[index % colors.length];
  }

  Widget _getProjectIcon(int index) {
    final icons = [
      const Icon(Icons.edit_note, color: Colors.teal),
      const Icon(Icons.build, color: Colors.red),
      const Icon(Icons.web, color: Colors.blue),
      const Icon(Icons.pie_chart, color: Colors.purple),
      const Icon(Icons.rocket_launch, color: Colors.orange),
    ];
    return icons[index % icons.length];
  }
}
