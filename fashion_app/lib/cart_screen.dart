import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/payment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'BottomNavBar.dart';
import 'editCardItem_screen.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchCartItems();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          List<dynamic> cart = userDoc.get('cart') ?? [];
          _cartItems = cart.map((item) {
            return {
              'productId': item['productId'],
              'images': item['images'],
              'name': item['name'],
              'quantity': item['quantity'],
              'sizes': item['sizes'],
              'colors': item['colors'],
              'price': item['price'], // Lấy giá tiền từ giỏ hàng
            };
          }).toList();
        }
      }
    } catch (e) {
      print("Error fetching cart data: $e");
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> removeItemFromCart(String productId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? uid = user?.uid;

      // Kiểm tra xem uid có null không
      if (uid == null) {
        print("User not logged in.");
        return;
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Lấy tài liệu người dùng
      final userDocSnapshot = await userDocRef.get();
      if (userDocSnapshot.exists) {
        var userData = userDocSnapshot.data();
        var cart = userData?['cart'] as List<dynamic>?;

        // Tìm và xóa phần tử trong cart có productId trùng khớp
        var itemToRemove = cart?.firstWhere((item) => item['productId'] == productId, orElse: () => null);

        if (itemToRemove != null) {
          // Cập nhật lại mảng cart trong Firestore, xóa phần tử có productId
          await userDocRef.update({
            'cart': FieldValue.arrayRemove([itemToRemove]),
          });

          // Xóa item trong mảng _cartItems từ local state
          setState(() {
            _cartItems.removeWhere((item) => item['productId'] == productId);
          });
        } else {
          print('Item not found in the cart.');
        }
      }

    } catch (e) {
      print('Error removing item: $e');
    }
  }





  // Hàm chuyển đổi màu sắc
  Color _getColor(String color) {
    switch (color) {
      case 'Black':
        return Colors.black; // Màu đỏ
      case 'White':
        return Colors.white; // Màu xanh
      case 'Red':
        return Colors.red; // Màu đỏ
      case 'Blue':
        return Colors.blue; // Màu xanh
      case "Navy":
        return Color(0xFF000080);
      default:
        return Colors.grey; // Màu mặc định
    }
  }

  void _navigateToUpdateCartItem(Map<String, dynamic> cartItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCartItemPage(cartItem: cartItem),
      ),
    );

    if (result == true) {
      // Cập nhật lại dữ liệu giỏ hàng ở đây
      _fetchCartItems(); // Giả sử bạn có hàm này để lấy lại dữ liệu giỏ hàng
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    double totalPrice = _cartItems.fold(0, (sum, item) {
      return sum + (item['price'] as int) * (item['quantity'] as int);
    });

    final formatCurrency = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: Colors.black38,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // Icon quay lại
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) => BottomNavBar(cart: [],),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0); // Bắt đầu từ trái
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
          },
        ),
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _cartItems.isEmpty
          ? Center(child: Text('Giỏ hàng của bạn trống!',style: TextStyle(color: Colors.white),))
          : Column(
        children: [
          Container(
            color: Colors.black,
            height: 710,
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Dismissible(
                  key: Key(item['productId']), // Mỗi item phải có một key duy nhất
                  direction: DismissDirection.endToStart, // Chỉ cho phép kéo từ phải qua trái
                  onDismissed: (direction) {
                    // Xóa item khỏi Firebase và mảng local
                    removeItemFromCart(item['productId']);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã xóa ${item['name']} khỏi giỏ hàng'),
                    ));
                  },
                  background: Container(
                    color: Colors.red, // Màu nền khi kéo item
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Gọi hàm _navigateToUpdateCartItem khi card được nhấn
                      _navigateToUpdateCartItem(item);
                    },
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.all(10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['images'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Số lượng: ${item['quantity']}'),
                                      Text(
                                        'Giá: ${formatCurrency.format((item['price'] as int) * (item['quantity'] as int))}đ',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Size: ${item['sizes']}'),
                                      const SizedBox(width: 85),
                                      Text('Màu sắc:'),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _getColor(item['colors']),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _getColor(item['colors']) == Colors.white
                                                ? Colors.black
                                                : Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.5),
                                              offset: Offset(0, 2),
                                              blurRadius: 2,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
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
                );
              },
            ),
          ),
          // Container hiển thị tổng tiền và nút thanh toán
          Container(
            // height: 70,
            padding: const EdgeInsets.all(10.0),
            // constraints: BoxConstraints(
            //   maxHeight: 500, // Đặt chiều cao tối đa cho Container
            // ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // Thay đổi vị trí bóng
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 0.0),
                  // Thêm khoảng cách phía trên
                  child: Text(
                    'Tổng tiền: ${formatCurrency.format(totalPrice)}đ',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 0.0),
                  // Thêm khoảng cách phía trên
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentScreen(cartItem: {},)),
                      );
                    },
                    child: const Text('Mua hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey, // Màu nền của nút
                      foregroundColor: Colors.white, // Màu chữ của nút
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
