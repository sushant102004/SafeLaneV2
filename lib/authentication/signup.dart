// ignore_for_file: unused_import, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelane/authentication/components/text_field.dart';
import 'package:safelane/authentication/login.dart';
import 'package:safelane/tabs/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SignUp extends StatelessWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailcontroller = TextEditingController();
    final name = TextEditingController();
    final passwordcontroller = TextEditingController();
    final confirmpasswordcontroller = TextEditingController();

    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFieldContainer(
                child: TextField(
                  controller: name,
                    decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.person),
                  hintText: "Enter your Name",
                  border: InputBorder.none,
                )),
              ),
              TextFieldContainer(
                child: TextField(
                    controller: emailcontroller,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.mail),
                      hintText: "Enter your email",
                      border: InputBorder.none,
                    )),
              ),
              TextFieldContainer(
                child: TextField(
                    controller: passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.lock),
                      hintText: "Enter your password",
                      border: InputBorder.none,
                    )),
              ),
              TextFieldContainer(
                child: TextField(
                    controller: confirmpasswordcontroller,
                    obscureText: false,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.visibility_off),
                      hintText: "Confirm your password",
                      border: InputBorder.none,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: size.width * 0.8,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailcontroller.text,
                      password: passwordcontroller.text,
                    )
                        .then((value) async {
                      User? user = FirebaseAuth.instance.currentUser;

                      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
                        'uid' : user.uid,
                        
                        'name' : name
                      });

                      print("Created New Account");
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const HomePage()));
                    }).onError((error, stackTrace) {
                      print("Error ${error.toString()}");
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Sign Up"),
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    color: const Color(0xffDBDBDB),
                    width: 80,
                    height: 5,
                  ),
                  Text(
                    "Or",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 20),
                    color: const Color(0xffDBDBDB),
                    width: 80,
                    height: 5,
                  ),
                ],
              ),
              const SizedBox(
                height: 35,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 25),
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff7A7A7A),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff7A7A7A),
                    ),
                    child: const Icon(
                      Icons.g_mobiledata,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 35,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account ? "),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const loginScreen()),
                        );
                      },
                      child: const Text("Login"))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
