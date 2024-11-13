import 'package:fashion_app/first_screen.dart';
import 'package:fashion_app/login_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'BottomNavBar.dart'; // Import Firebase Core

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Đảm bảo Flutter đã được khởi tạo
  await Firebase.initializeApp();
  // Kích hoạt App Check với Play Integrity provider
  await FirebaseAppCheck.instance.activate();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FirstScreen(),
      ),
    );
  }
}
