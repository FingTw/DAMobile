import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/database_service.dart';

class MemberManagementScreen extends StatefulWidget {
  final Project project;
  const MemberManagementScreen({super.key, required this.project});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool get amIPO => widget.project.members[currentUserId] == 'PO';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Members", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Code: ${widget.project.joinCode}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                  Text("Limit: ${widget.project.maxMembers}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ]),
                if (amIPO) const Chip(label: Text("Owner"), backgroundColor: Colors.orangeAccent)
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: DatabaseService().getProjectMembers(widget.project.members.keys.toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String role = widget.project.members[user.uid] ?? 'Dev';
                    final bool isMe = user.uid == currentUserId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                        child: user.avatarUrl.isEmpty
                            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "?") // <--- FIX HERE
                            : null,
                      ),                      title: Text(user.name),
                      subtitle: Text(role),
                      trailing: amIPO && !isMe
                          ? DropdownButton<String>(
                          value: role,
                          items: ['SM', 'Dev'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) {
                            if(val != null) {
                              DatabaseService().updateMemberRole(widget.project.id, user.uid, val);
                              setState(() => widget.project.members[user.uid] = val);
                            }
                          })
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}