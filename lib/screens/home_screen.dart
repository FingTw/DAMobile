
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/screens/dashboard_view.dart';
import 'package:untitled3/screens/project_list_screen.dart';
import 'package:untitled3/screens/public_profile_view.dart';
import 'package:untitled3/screens/task_screen.dart'; // RESTORED
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/login_screen.dart';
import 'package:untitled3/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Gọi hàm đồng bộ ID ngay khi Home Screen được khởi tạo
    NotificationService.syncOneSignalId();
  }

  // RESTORED TaskScreen
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardView(),
    ProjectListScreen(),
    TaskScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const LoginScreen(); 
    }

    return StreamBuilder<UserModel?>(
      stream: DatabaseService(uid: currentUser.uid).userData,
      builder: (context, snapshot) {
        final UserModel? userData = snapshot.data;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  if (userData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PublicProfileView(user: userData)),
                    );
                  }
                },
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                   backgroundColor: Colors.grey[200],
                   backgroundImage: (userData?.avatarUrl != null && userData!.avatarUrl.isNotEmpty)
                      ? NetworkImage(userData.avatarUrl)
                      : null,
                  child: (userData?.avatarUrl == null || userData!.avatarUrl.isEmpty)
                      ? Icon(Icons.person, color: Colors.grey[800])
                      : null,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(
                  userData?.name ?? "User",
                  style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                 Text(
                  "Welcome back!",
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ]
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await authService.signOut();
                  if(mounted) {
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
               BottomNavigationBarItem(
                icon: Icon(Icons.folder_copy_rounded),
                label: 'Projects',
              ),
              // RESTORED My Tasks tab
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt_rounded),
                label: 'My Tasks',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.deepPurpleAccent,
            onTap: _onItemTapped,
          ),
        );
      }
    );
  }
}
