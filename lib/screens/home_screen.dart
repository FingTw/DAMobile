
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/screens/dashboard_view.dart';
import 'package:untitled3/screens/project_list_screen.dart';
import 'package:untitled3/screens/public_profile_view.dart';
import 'package:untitled3/screens/task_screen.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/login_screen.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/services/daily_notification_service.dart';
import 'package:untitled3/providers/project_provider.dart';
import 'package:untitled3/providers/project_task_provider.dart';
import 'package:untitled3/data/repositories/project_repository.dart';
import 'package:untitled3/data/repositories/project_task_repository.dart';


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
    _showDailyNotifications();
  }

  Future<void> _showDailyNotifications() async {
    // Đợi một chút để UI load xong
    await Future.delayed(const Duration(seconds: 1));
    await DailyNotificationService.checkAndShowDailyNotifications();
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(
            ProjectRepository(uid: currentUser.uid),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectTaskProvider(
            ProjectTaskRepository(uid: currentUser.uid),
          ),
        ),
      ],
      child: StreamBuilder<UserModel?>(
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
      ),
    );
  }
}
