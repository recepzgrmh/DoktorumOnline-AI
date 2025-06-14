import 'package:flutter/material.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/screens/test_screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Opening()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade100],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                // User profile header
                UserAccountsDrawerHeader(
                  accountName: Text(
                    currentUser?.displayName ?? 'User',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  accountEmail: Text(
                    currentUser?.email ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Home list tile
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'HOME',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),

                // Chat list tile
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'OLD CHATS',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                OldChatScreen(userId: currentUser!.uid),
                      ),
                    );
                  },
                ),

                // File Upload list tile
                _buildDrawerItem(
                  icon: Icons.upload_file_rounded,
                  title: 'FILE UPLOAD',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TestScreen()),
                    );
                  },
                ),
              ],
            ),

            // Logout list tile
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: 'LOGOUT',
                textColor: Colors.red.shade700,
                iconColor: Colors.red.shade700,
                onTap: signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: iconColor ?? Colors.blue.shade600, size: 26),
        title: Text(
          title,
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.blue.shade600,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.blue.shade50,
        selectedTileColor: Colors.blue.shade50,
      ),
    );
  }
}
