import 'package:flutter/material.dart';
import 'package:login_page/screens/sign_in.dart';
import 'package:login_page/screens/sign_up.dart';
import 'package:login_page/widgets/custom_button.dart';

class Opening extends StatelessWidget {
  const Opening({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: "Sign In!",
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignIn()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  label: "Sign Up!",
                  backgroundColor: Colors.green,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
