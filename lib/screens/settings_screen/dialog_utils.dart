import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DialogUtils {
  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String? subText,
    String? confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Colors.red, size: 28),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor ?? Colors.red,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subText != null) ...[
                const SizedBox(height: 8),
                Text(
                  subText,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancelText ?? 'cancel'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText ?? 'accept'.tr()),
            ),
          ],
        );
      },
    );
  }
}
