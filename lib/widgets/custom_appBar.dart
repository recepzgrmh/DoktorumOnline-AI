import 'package:flutter/material.dart';

class CustomAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final GlobalKey? menuKey;

  const CustomAppbar({
    super.key,
    required this.title,
    this.actions,
    this.menuKey,
  });

  @override
  State<CustomAppbar> createState() => _CustomAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppbarState extends State<CustomAppbar> {
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
