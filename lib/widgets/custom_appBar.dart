import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Opening()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: theme.primaryColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: theme.primaryColor,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          color: theme.primaryColor,
        ),
      ],
    );
  }
}
