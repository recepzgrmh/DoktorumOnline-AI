import 'package:flutter/material.dart';

class TextInputs extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final bool isPassword;
  final bool isEmail;
  final bool isFlexible; // Yeni parametre: Row içinde kullanım için

  const TextInputs({
    super.key,
    required this.labelText,
    required this.controller,
    this.isPassword = false,
    this.isEmail = false,
    this.isFlexible = false, // Varsayılan olarak false
  });

  @override
  _TextInputsState createState() => _TextInputsState();
}

class _TextInputsState extends State<TextInputs> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.blue;
    const Color textColor = Color(0xFF2D3142);
    final Color hintColor = Colors.grey.shade600;
    final Color borderColor = Colors.grey.shade300;
    const Color errorColor = Colors.redAccent;
    const Color fillColor = Colors.white;

    Widget textField = TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType:
          widget.isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(
        fontSize: 16,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelText: widget.labelText,
        labelStyle: TextStyle(color: hintColor, fontSize: 16),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
        suffixIcon:
            widget.isPassword
                ? IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
                : (widget.isEmail
                    ? const Icon(Icons.alternate_email_rounded)
                    : null),
        suffixIconColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused) &&
              !states.contains(MaterialState.error)) {
            return Colors.blue;
          }
          if (states.contains(MaterialState.error)) {
            return errorColor;
          }
          return hintColor;
        }),
      ),
    );

    // Eğer Row içinde kullanılacaksa Expanded ile sar
    if (widget.isFlexible) {
      return Expanded(child: textField);
    }

    return textField;
  }
}
