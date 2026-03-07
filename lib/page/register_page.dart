import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'home_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void register() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // 🔥 После регистрации сразу в HomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  HomePage( currentUserEmail:  FirebaseAuth.instance.currentUser!.email!,)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1418),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28.sp,
              backgroundColor: Colors.green,
              child: Icon(
                Icons.person_add_alt_1,
                size: 30.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              "Create Account",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            buildField("Email", emailController),
            SizedBox(height: 2.h),
            buildField("Password", passwordController, obscure: true),
            SizedBox(height: 4.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                minimumSize: Size(double.infinity, 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: register,
              child: Text(
                "Register",
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: Text(
                "Already have account? Login",
                style: TextStyle(color: Colors.blue, fontSize: 15.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String hint, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1F2C34),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}