import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:safelane/tabs/home.dart';

class GoogleAuth extends StatefulWidget {
  const GoogleAuth({super.key});

  @override
  State<GoogleAuth> createState() => _GoogleAuthState();
}

class _GoogleAuthState extends State<GoogleAuth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Sign in with Google'),
          onPressed: () async {
            final GoogleSignInAccount? googleUser =
                await GoogleSignIn().signIn();

            final GoogleSignInAuthentication? googleAuth =
                await googleUser?.authentication;

            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth?.accessToken,
              idToken: googleAuth?.idToken,
            );

            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          },
        ),
      ),
    );
  }
}
