import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: WaveClipperTwo(flip: true),
            child: Container(
              color: Colors.yellow[600],
              height: 235,
              alignment: Alignment.center,
              child: const Text(
                'WELCOME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signIn');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6C700),
                    foregroundColor: Colors.black,
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.login,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/createAccount');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Color(0xFFF6C700), width: 1.5),
                    ),
                  ),
                  icon: const Icon(
                    Icons.person_add,
                    color: Color(0xFFF6C700),
                    size: 20,
                  ),
                  label: const Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              'By continuing, you agree to our Terms & Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          ClipPath(
            clipper: WaveClipperTwo(flip: true,reverse: true),
            child: Container(
              color: Colors.yellow[600],
              height: 150,
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }
}