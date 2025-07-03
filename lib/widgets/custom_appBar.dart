import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final GlobalKey? menuKey;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.menuKey,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
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
    );
  }
}
