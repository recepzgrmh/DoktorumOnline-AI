import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;

  // Style parameters
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double verticalPadding;
  final double horizontalPadding;
  final double minHeight;
  final double elevation;
  final BorderRadiusGeometry borderRadius;
  final TextStyle? textStyle;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.borderColor,
    this.verticalPadding = 16.0,
    this.horizontalPadding = 24.0,
    this.minHeight = 48.0,
    this.elevation = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.textStyle,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle =
        isOutlined
            ? OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(
                color: borderColor ?? foregroundColor,
                width: 1.5,
              ),
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              minimumSize: Size(
                isFullWidth ? double.infinity : (width ?? 0),
                minHeight,
              ),
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            )
            : ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              minimumSize: Size(
                isFullWidth ? double.infinity : (width ?? 0),
                minHeight,
              ),
              elevation: elevation,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            );

    final buttonChild =
        isLoading
            ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(
                  label,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            );

    return isOutlined
        ? OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        )
        : ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
  }
}
