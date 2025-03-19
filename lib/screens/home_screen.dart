import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final user = FirebaseAuth.instance.currentUser;

  signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HomePage")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text("Hoşgeldin ${user!.email}")),
          ElevatedButton(
            onPressed: signOut,
            child: const Icon(Icons.login_rounded),
          ),
        ],
      ),
    );
  }
}
