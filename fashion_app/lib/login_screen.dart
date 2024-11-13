import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/home_screen.dart';
import 'package:fashion_app/register_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'BottomNavBar.dart';
import 'admin_screen.dart';
import 'cart_screen.dart';
import 'forgetPassword_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _errorMessage = '';



  void _login() async {
    try {
      if (_email == 'admin@gmail.com') {
        // Kiểm tra trong collection admin của Firestore
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('admins')  // Collection chứa tài khoản admin
            .where('email', isEqualTo: _email)  // Tìm tài khoản theo email
            .where('role', isEqualTo: 'admin')  // Kiểm tra role là 'admin'
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Lấy dữ liệu của tài liệu đầu tiên (tài liệu khớp với điều kiện)
          Map<String, dynamic> adminData = querySnapshot.docs.first.data() as Map<String, dynamic>;

          // So sánh mật khẩu
          if (_password == adminData['password']) {
            // Điều hướng tới màn hình admin nếu mật khẩu trùng khớp
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen()), // Màn hình admin của bạn
            );
          } else {
            setState(() {
              _errorMessage = 'Sai mật khẩu cho tài khoản admin';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Tài khoản admin không tồn tại';
          });
        }

      } else {
        // Xử lý đăng nhập cho người dùng bình thường
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          List<dynamic> cart = userData['cart'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavBar(cart: []), // Điều hướng tới trang người dùng bình thường
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Người dùng không tồn tại trong Firestore';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi đăng nhập: $e';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black, // Background color
      ),
      home: Scaffold(
        appBar: AppBar(

          title: const Text(
            'Đăng nhập',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                height: 720,
                color: Colors.black,
                padding: const EdgeInsets.all(0.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GoodOldDays Outlet',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Chào mừng bạn đến với ứng dụng mua sắm thời trang GoodOldDays Outlet, hy vọng bạn sẽ có trải nghiệm tốt khi sử dụng ứng dụng.',
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Gmail',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: CupertinoColors.extraLightBackgroundGray,
                                border: const OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                return null;
                              },
                              onChanged: (value) => _email = value,
                            ),
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Mật khẩu',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              obscureText: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: CupertinoColors.extraLightBackgroundGray,
                                border: const OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return null;
                              },
                              onChanged: (value) => _password = value,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()), // Thay RegisterPage bằng trang đăng ký của bạn
                                  );
                                  print('Forgot Password pressed');
                                },
                                child: const Text(
                                  'Quên Mật Khẩu?',
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: _login, // Call _login when pressed
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey, // Background color
                                  foregroundColor: Colors.white, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                ),
                                child: const Text('Đăng nhập'),
                              ),
                            ),
                            if (_errorMessage.isNotEmpty)
                              Text(_errorMessage, style: TextStyle(color: Colors.blueGrey)),
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Điều hướng đến trang đăng ký
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterScreen()), // Thay RegisterPage bằng trang đăng ký của bạn
                                  );
                                },
                                child: Text(
                                  'Chưa có tài khoản? Đăng kí ngay',
                                  style: TextStyle(
                                    color: Colors.blueGrey, // Màu sắc theo ý bạn
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Add Google sign-up action here
                                  },
                                  icon: Image.asset('assets/images/ggicon.png'),
                                  iconSize: 40,
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  onPressed: () {
                                    // Add Facebook sign-up action here
                                  },
                                  icon: Image.asset('assets/images/fbicon.png'),
                                  iconSize: 40,
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  onPressed: () {
                                    // Add phone sign-up action here
                                  },
                                  icon: Image.asset('assets/images/phoneicon.png'),
                                  iconSize: 40,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




