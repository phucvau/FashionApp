import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/login_screen.dart';
import 'package:fashion_app/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import 'account_screen.dart';

class BottomNavBar extends StatefulWidget {
  final List<dynamic> cart; // Thêm cart vào constructor

  const BottomNavBar({Key? key, required this.cart}) : super(key: key);

  // Phương thức tĩnh để cập nhật giỏ hàng
  static Future<void> fetchCartItemCount(BuildContext context) async {
    final state = context.findAncestorStateOfType<_BottomNavBarState>();
    if (state != null) {
      await state._getCartItemCount(); // Gọi hàm _getCartItemCount
    }
  }

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 0;
  int cartItemCount = 0; // Biến để lưu số lượng sản phẩm trong giỏ hàng

  @override
  void initState() {
    super.initState();
    _getCartItemCount(); // Gọi hàm lấy số lượng sản phẩm khi khởi tạo
  }


  // Hàm để lấy số lượng sản phẩm trong giỏ hàng từ Firestore
  Future<void> _getCartItemCount() async {
    try {
      // Lấy uid của người dùng hiện tại
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Truy vấn Firestore để lấy giỏ hàng của người dùng
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          List<dynamic> cart = userDoc.get('cart') ?? [];
          setState(() {
            cartItemCount = cart.length; // Đếm số lượng sản phẩm trong giỏ
          });
        }
      }
    } catch (e) {
      print("Error fetching cart data: $e");
    }
  }

  @override
  void dispose() {
    // Hủy bỏ bất kỳ đối tượng nào gây ra callback không cần thiết
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      CartPage(),
      NotificationScreen(),
      const AccountScreen(),
    ];
    // Tính toán chiều cao của BottomNavigationBar dựa trên chỉ số hiện tại
    double bottomNavBarHeight = currentIndex == 1 ? 0 : 65.h;

    return Scaffold(
      body: Stack(
        children: [
          _screens[currentIndex],
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 0.0).r,
              duration: const Duration(milliseconds: 0), // Thời gian hoạt ảnh
              height: bottomNavBarHeight,
              child: Container(
                height: double.infinity.h,
                width: 328.h,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(15.0)).r,
                  child: BottomNavigationBar(
                    backgroundColor: Colors.black,
                    currentIndex: currentIndex,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.grey,
                    onTap: (index) {
                      if (mounted) {
                        if (index == 1) { // Nếu nhấn vào giỏ hàng
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 500), // Thời gian hoạt ảnh
                              pageBuilder: (context, animation, secondaryAnimation) => CartPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0); // Bắt đầu từ dưới
                                const end = Offset(0.0, 0.0); // Điểm kết thúc là tại vị trí bình thường
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        } else {
                          // Thay đổi index bình thường nếu không phải là giỏ hàng
                          setState(() {
                            currentIndex = index;
                          });
                        }
                      }
                    },

                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Iconsax.home),
                        label: 'Trang chủ',
                      ),
                      BottomNavigationBarItem(
                        icon: Stack(
                          children: [
                            const Icon(Iconsax.bag_2), // Biểu tượng giỏ hàng
                            if (cartItemCount > 0) // Nếu có sản phẩm trong giỏ hàng
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(6),
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    cartItemCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: 'Giỏ hàng',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Iconsax.alarm),
                        label: 'Thông báo',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Iconsax.user),
                        label: 'Tài khoản',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
