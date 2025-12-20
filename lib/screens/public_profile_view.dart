
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/screens/profile_screen.dart'; 

class PublicProfileView extends StatelessWidget {
  final UserModel user;

  const PublicProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyProfile = currentUser != null && currentUser.uid == user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(user.name, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty 
                  ? Icon(Icons.person, size: 70, color: Colors.grey[400]) 
                  : null,
            ),
            const SizedBox(height: 15),
            Text(user.name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user.email, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 30),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if(user.workplace.isNotEmpty) _buildInfoChip(icon: Icons.work_outline, text: user.workplace),
                if(user.age != null) _buildInfoChip(icon: Icons.cake_outlined, text: "${user.age} years old"),
                if(user.zodiacSign.isNotEmpty) _buildInfoChip(icon: Icons.brightness_3_outlined, text: user.zodiacSign),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(
      avatar: Icon(icon, color: Colors.purple, size: 20),
      label: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.purple.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
