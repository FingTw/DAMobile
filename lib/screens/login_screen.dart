
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:untitled3/screens/home_screen.dart';
import 'package:untitled3/screens/signup_screen.dart';
import 'package:untitled3/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    setState(() { _isLoading = true; });

    final String? error = await _authService.signInWithEmailAndPassword(_emailController.text, _passwordController.text);

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _googleSignIn() async {
    setState(() { _isLoading = true; });
    final String? error = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 120),
            FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: Text("Sign In", style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 50),
            FadeInUp(duration: const Duration(milliseconds: 1200), child: _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined)),
            const SizedBox(height: 25),
            FadeInUp(duration: const Duration(milliseconds: 1300), child: _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock_outline, isPassword: true)),
            const SizedBox(height: 25),
            FadeInUp(
              duration: const Duration(milliseconds: 1400),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : () {},
                  child: Text("Forgot Password?", style: GoogleFonts.poppins(color: Colors.blue[700], fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(duration: const Duration(milliseconds: 1500), child: _buildLoginButton()),
            const SizedBox(height: 50),
            FadeInUp(duration: const Duration(milliseconds: 1600), child: _buildDivider()),
            const SizedBox(height: 50),
            FadeInUp(duration: const Duration(milliseconds: 1700), child: _buildGoogleSignInButton()),
            const SizedBox(height: 50),
            FadeInUp(duration: const Duration(milliseconds: 1800), child: _buildSignUpLink()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: isPassword,
      decoration: InputDecoration(
        label: Text(label, style: GoogleFonts.poppins(color: Colors.grey[700])),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.3), spreadRadius: 1, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Sign In", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [Expanded(child: Divider(color: Colors.grey[300])), Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text("OR", style: GoogleFonts.poppins(color: Colors.grey[600]))), Expanded(child: Divider(color: Colors.grey[300]))]);
  }

  Widget _buildGoogleSignInButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _googleSignIn,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), spreadRadius: 1, blurRadius: 10)],
          ),
          child: Image.asset('assets/google_logo.png', height: 24),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: GoogleFonts.poppins(color: Colors.grey[600])),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
          child: Text("Sign Up", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[800])),
        ),
      ],
    );
  }
}
