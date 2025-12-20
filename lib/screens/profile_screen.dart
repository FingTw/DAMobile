
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  bool _isDataInitialized = false; // FIX: Flag to prevent overwriting user input
  
  final _nameController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _zodiacController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _workplaceController.dispose();
    _zodiacController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() { 
        _imageFile = File(pickedFile.path); 
        _isLoading = true; // Show loading indicator on avatar
      });
      final newAvatarUrl = await _uploadAvatar(currentUser!.uid);
      if (newAvatarUrl != null) {
        await DatabaseService(uid: currentUser!.uid).updateUserAvatar(newAvatarUrl);
      }
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<String?> _uploadAvatar(String uid) async {
    if (_imageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload avatar: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() { _isLoading = true; });
    
    await DatabaseService(uid: currentUser!.uid).updateUserData(
      name: _nameController.text.trim(),
      workplace: _workplaceController.text.trim(),
      zodiacSign: _zodiacController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
    );

    if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        title: Text("Edit Profile", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<UserModel?>(
        stream: DatabaseService(uid: currentUser!.uid).userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isDataInitialized) {
               return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
               return const Center(child: Text("Could not load user data."));
          }
          
          if (snapshot.hasData && snapshot.data != null && !_isDataInitialized) {
            UserModel userData = snapshot.data!;
            _nameController.text = userData.name;
            _workplaceController.text = userData.workplace;
            _zodiacController.text = userData.zodiacSign;
            _ageController.text = userData.age?.toString() ?? '';
            _isDataInitialized = true; // Mark as initialized
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                 _buildAvatar(snapshot.data),
                 const SizedBox(height: 30),
                _buildInfoCard(),
                const SizedBox(height: 30),
                _buildSaveButton(_updateProfile),
              ],
            ),
          );
        },
      ),
    );
  }

   Widget _buildAvatar(UserModel? userData) {
     return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 5, blurRadius: 20)],
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null 
                      ? FileImage(_imageFile!) 
                      : (userData?.avatarUrl.isNotEmpty == true 
                          ? NetworkImage(userData!.avatarUrl) 
                          : null) as ImageProvider?,
                  child: (_imageFile == null && (userData?.avatarUrl.isEmpty ?? true))
                      ? Icon(Icons.person, color: Colors.grey[400], size: 60)
                      : null,
                ),
              ),
            ),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
     return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_outline, enabled: !_isLoading),
            const SizedBox(height: 20),
            _buildTextField(controller: _workplaceController, label: "Workplace", icon: Icons.work_outline, enabled: !_isLoading),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _zodiacController, label: "Zodiac Sign", icon: Icons.brightness_3_outlined, enabled: !_isLoading)),
                const SizedBox(width: 20),
                Expanded(child: _buildTextField(controller: _ageController, label: "Age", icon: Icons.cake_outlined, keyboardType: TextInputType.number, enabled: !_isLoading)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool enabled = true, TextInputType? keyboardType}) {
    return TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label, 
          hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
        ),
      );
  }

  Widget _buildSaveButton(VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), spreadRadius: 1, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Save Changes", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
