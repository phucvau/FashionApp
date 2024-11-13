import 'package:fashion_app/login_screen.dart';
import 'package:fashion_app/paypal_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'confirmedOrder_screen.dart';
import 'orderHistory_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? avatarUrl;
  String? name;
  String? phone;
  String? address;
  String? email;
  int selectedOptionIndex = -1; // Biến lưu trữ chỉ số của ô được chọn

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void toggleSelection(int index) {
    setState(() {
      selectedOptionIndex = index; // Cập nhật chỉ số ô được chọn
    });
  }


  Future<void> _loadUserData() async {
    final data = await _getUserData();
    if (mounted) { // Check if the widget is still in the widget tree
      setState(() {
        avatarUrl = data['avatarUrl'];
        name = data['name'];
        phone = data['phone'];
        address = data['address'];
        email = data['email'];
      });
    }
  }


  Future<Map<String, dynamic>> _getUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User chưa đăng nhập');

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<void> _updateUserData(Map<String, dynamic> newData) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(newData, SetOptions(merge: true));

    await _loadUserData(); // Cập nhật dữ liệu trong UI
  }

  Future<void> _showEditModal(BuildContext context) {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên')),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Số điện thoại')),
              TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Địa chỉ')),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _updateUserData({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'address': addressController.text,
                  });
                  Navigator.pop(context);
                },
                child: Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print('Không có ảnh nào được chọn');
      return; // Không có ảnh nào được chọn
    }

    final File imageFile = File(pickedFile.path);
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('User chưa đăng nhập');
      return; // Người dùng chưa đăng nhập
    }

    // Tải ảnh lên Firebase Storage và lấy URL ảnh đã lưu
    try {
      String downloadUrl = await _uploadImageToFirestore(imageFile);
      await _updateUserData({'avatarUrl': downloadUrl});
    } catch (e) {
      print('Lỗi khi tải ảnh lên: ${e.toString()}');
    }
  }

  Future<String> _uploadImageToFirestore(File image) async {
    try {
      // Tạo tham chiếu đến Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars/${FirebaseAuth.instance.currentUser!.uid}.jpg');

      // Tải ảnh lên Firebase Storage
      await storageRef.putFile(image);

      // Lấy URL của ảnh vừa tải lên
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Lỗi khi tải ảnh lên: $e');
      throw Exception('Không thể tải ảnh lên');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            Text('Thông Tin Tài Khoản', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: name == null // Thay đổi điều kiện để kiểm tra tên
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              GestureDetector(
                onTap: () => _showEditModal(context),
                child: Container(
                  height: 150,
                  padding: EdgeInsets.all(16.0),
                  // margin: EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80, // Chiều rộng tổng thể của Container
                          height: 80, // Chiều cao tổng thể của Container
                          decoration: BoxDecoration(
                            shape:
                                BoxShape.circle, // Đặt hình dạng là hình tròn
                            color: Colors.black, // Màu nền của viền
                            border: Border.all(
                              color: Colors.black, // Màu viền
                              width:
                                  1.0, // Độ dày của viền (tăng giá trị này để làm viền dày hơn)
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl!)
                                : AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Bạn chưa đặt nickname',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5.h),
                          Text(email ?? 'Không có email',
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey)),
                          SizedBox(height: 5.h),
                          Text(phone ?? 'Bạn chưa thêm số điện thoại',
                              style: TextStyle(fontSize: 14.sp)),
                          SizedBox(height: 5.h),
                          Text(address ?? 'Bạn chưa thêm địa chỉ',
                              style: TextStyle(fontSize: 14.sp)),
                        ],
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditModal(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OrderHistoryScreen()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.3),  // Viền đen ở phía trên
                    ),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.blueGrey,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đơn hàng của bạn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreen()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.3),  // Viền đen ở phía trên
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  color: Colors.blueGrey,
                  size: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        )
            ]),
    );
  }
}
