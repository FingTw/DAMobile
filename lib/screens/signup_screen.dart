
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:untitled3/screens/home_screen.dart';
import 'package:untitled3/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _signUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() { _isLoading = true; });

    final String? error = await _authService.registerWithEmailAndPassword(_nameController.text, _emailController.text, _passwordController.text);
    
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.of(context).pop())),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              FadeInDown(duration: const Duration(milliseconds: 1000), child: Text("Create Account", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black))),
              const SizedBox(height: 40),
              FadeInUp(duration: const Duration(milliseconds: 1200), child: _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_outline)),
              const SizedBox(height: 20),
              FadeInUp(duration: const Duration(milliseconds: 1300), child: _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined)),
              const SizedBox(height: 20),
              FadeInUp(duration: const Duration(milliseconds: 1400), child: _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock_outline, isPassword: true)),
              const SizedBox(height: 20),
              FadeInUp(duration: const Duration(milliseconds: 1500), child: _buildTextField(controller: _confirmPasswordController, label: "Confirm Password", icon: Icons.lock_outline, isPassword: true)),
              const SizedBox(height: 40),
              FadeInUp(duration: const Duration(milliseconds: 1600), child: _buildSignUpButton()),
              const SizedBox(height: 40),
              FadeInUp(duration: const Duration(milliseconds: 1700), child: _buildSignInLink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          icon: Padding(padding: const EdgeInsets.only(left: 15.0), child: Icon(icon, color: Colors.grey[400])),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), spreadRadius: 1, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Sign Up", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?", style: GoogleFonts.poppins(color: Colors.grey[600])),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text("Sign In", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[800])),
        ),
      ],
    );
  }
}
