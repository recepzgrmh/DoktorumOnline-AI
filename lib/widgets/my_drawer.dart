import 'package:flutter/material.dart';

import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/opening.dart';

import 'package:login_page/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => Opening()));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // logo
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Doktorum Online AI',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // home list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: Text(
                    'HOME',
                    style: TextStyle(
                      letterSpacing: 7,
                      color: const Color.fromARGB(193, 105, 105, 105),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: Icon(
                    Icons.home,
                    color: Color.fromARGB(193, 105, 105, 105),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              // Chat
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: Text(
                    'OLD  CHATS',
                    style: TextStyle(
                      letterSpacing: 7,
                      color: const Color.fromARGB(193, 105, 105, 105),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: Icon(
                    Icons.chat,
                    color: Color.fromARGB(193, 105, 105, 105),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OldChatScreen()),
                    );
                  },
                ),
              ),

              //settings list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: Text(
                    'SETTINGS',
                    style: TextStyle(
                      letterSpacing: 7,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(193, 105, 105, 105),
                    ),
                  ),
                  leading: Icon(
                    Icons.settings,
                    color: Color.fromARGB(193, 105, 105, 105),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          //logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 25),
            child: ListTile(
              title: Text(
                'LOGOUT',
                style: TextStyle(
                  letterSpacing: 7,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(199, 244, 67, 54),
                ),
              ),
              leading: Icon(
                Icons.logout,
                color: const Color.fromARGB(199, 244, 67, 54),
              ),
              onTap: signOut,
            ),
          ),
        ],
      ),
    );
  }
}
