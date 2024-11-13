import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/BottomNavBar.dart';
import 'package:fashion_app/cart_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'confirmedOrder_screen.dart';
import 'editCardItem_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> cartItem; // Thông tin sản phẩm trong giỏ hàng

  const PaymentScreen({Key? key, required this.cartItem}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isMounted = false;

  String? avatarUrl;
  String? name;
  String? phone;
  String? address;
  String? email;

  int selectedOptionIndex = -1; // Biến lưu trữ chỉ số của ô được chọn

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchCartItems();
    _loadUserData();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void toggleSelection(int index) {
    setState(() {
      selectedOptionIndex = index; // Cập nhật chỉ số ô được chọn
    });
  }

  Future<void> handlePayment() async {
    if (selectedOptionIndex == 0) {
      // Nếu ô "Thanh toán khi nhận hàng" được chọn
      // Lấy user hiện tại từ Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Kiểm tra nếu currentUser không null
      if (currentUser != null) {
        String userId = currentUser.uid;

        // Tham chiếu đến tài liệu của người dùng trong Firestore
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

        // Lấy dữ liệu của người dùng hiện tại
        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists) {
          // Lấy giá trị từ tài liệu
          String address = userDoc.get('address');
          String name = userDoc.get('name');
          String phone = userDoc.get('phone');
          List cart = userDoc.get('cart');

          // Tạo một orderId ngẫu nhiên
          String orderId = Random().nextInt(1000000).toString();

          // Tạo đối tượng order mới với các trạng thái và thông tin từ document
          Map<String, dynamic> newOrder = {
            'orderId': orderId,
            'address': address,
            'name': name,
            'phone': phone,
            'cart': cart,
            'isGoing': true,
            'isCompleted': false,
            'isCancelled': false,
            'orderDate': DateTime.now() // Thêm ngày đặt hàng nếu cần
          };

          // Thêm đơn hàng mới vào orderHistory
          await userRef.update({
            'orderHistory': FieldValue.arrayUnion([newOrder])
          });
        } else {
          print("User document does not exist");
        }
      } else {
        print("User is not logged in");
      }

      clearCart();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfirmedOrderScreen()),
      );
    } else if (selectedOptionIndex == 1) {
      // Nếu ô "Paypal" được chọn
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => PaypalCheckout(
          sandboxMode: true,
          clientId:
              "AV8aDpnOL26z0vO4yjoDAGgeFhH3UH0B51hknZ0AKFMGzZGQv0p-USwwmPtHFYb-JuZTF1Zcz5ruwYls",
          secretKey:
              "EAu4nm2Siqrbe8ZynK1cS6UnDprCPqxtxtgYvyyg4hrQIJoXTzrAPEYzwX4GMWTDiJ_aVkEiZCRiFCun",
          returnURL: "app://success",
          // Sử dụng scheme URL để điều hướng trong ứng dụng
          cancelURL: "app://cancel",
          // Sử dụng scheme URL để điều hướng trong ứng dụng
          transactions: const [
            {
              "amount": {
                "total": '70',
                "currency": "USD",
                "details": {
                  "subtotal": '70',
                  "shipping": '0',
                  "shipping_discount": 0
                }
              },
              "description": "The payment transaction description.",
              "item_list": {
                "items": [
                  {
                    "name": "Apple",
                    "quantity": 4,
                    "price": '5',
                    "currency": "USD"
                  },
                  {
                    "name": "Pineapple",
                    "quantity": 5,
                    "price": '10',
                    "currency": "USD"
                  }
                ],
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) {
            // Điều hướng đến màn hình thành công
            clearCart();  // Làm sạch giỏ hàng

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ConfirmedOrderScreen()),
            );
          },
          onError: (error) {
            print("onError: $error");
            Navigator.pop(context);
          },
          onCancel: () {
            // Điều hướng đến màn hình hủy
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                        cartItem: {},
                      )),
            );
          },
        ),
      ));
    } else {
      // Thông báo người dùng chọn phương thức thanh toán
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn phương thức thanh toán!')),
      );
    }
  }

  Future<void> clearCart() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userId = currentUser.uid;
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

        await userRef.update({
          'cart': []
        });

        print("Cart cleared successfully.");
      } else {
        print("User is not logged in.");
      }
    } catch (e) {
      print("Error clearing cart: $e");
    }
  }


  Future<void> _loadUserData() async {
    final data = await _getUserData();
    setState(() {
      avatarUrl = data['avatarUrl'];
      name = data['name'];
      phone = data['phone'];
      address = data['address'];
      email = data['email'];
    });
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

    // Phí vận chuyển và mã giảm giá mặc định
    double shippingFee = 15000.0;  // Mặc định 15.000đ
    double discount = 0.0;  // Mặc định 0đ

    // Tính tổng thanh toán
    double totalPayment = totalPrice - shippingFee - discount;

    final formatCurrency = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // Icon quay lại
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CartPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0); // Bắt đầu từ trái
                  const end = Offset(
                      0.0, 0.0); // Điểm kết thúc là tại vị trí bình thường
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

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
          'Thanh toán',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _cartItems.isEmpty
          ? Center(child: Text('Giỏ hàng của bạn trống!'))
          : Column(children: [
              Expanded(
                  child: ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    margin: EdgeInsets.symmetric(horizontal: 0.0),
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
                          child: Container(
                            width: 80, // Chiều rộng tổng thể của Container
                            height: 80, // Chiều cao tổng thể của Container
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Đặt hình dạng là hình tròn
                              color: Colors.black,
                              // Màu nền của viền
                              border: Border.all(
                                color: Colors.black, // Màu viền
                                width:
                                    1.0, // Độ dày của viền (tăng giá trị này để làm viền dày hơn)
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  // Màu bóng
                                  spreadRadius: 2,
                                  // Độ lan tỏa của bóng
                                  blurRadius: 5,
                                  // Độ mờ của bóng
                                  offset: Offset(0, 3), // Vị trí bóng
                                ),
                              ],
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
                        Container(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? 'Bạn chưa đặt nickname',
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold),
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
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditModal(context),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 5),

                  //List products
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 0.0),
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
                    child: Column(
                      children: _cartItems.map((item) {
                        return GestureDetector(
                          onTap: () {
                            _navigateToUpdateCartItem(item); // Gọi hàm tại đây
                          },
                          child: Card(
                            color: Colors.white,
                            margin: EdgeInsets.only(
                              left: 10.0,
                              right: 10.0,
                              top: 2.0,
                              bottom: 10.0,
                            ),
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
                                            Text('Size: ${(item['sizes'])}'),
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
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),

                  // phương thức thanh toán
                  Container(
                    padding: EdgeInsets.all(16.0),
                    margin: EdgeInsets.symmetric(horizontal: 0.0),
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Phương thức thanh toán',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/cash.png',
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Thanh toán khi nhận hàng',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () => toggleSelection(0),
                              // Gọi hàm với chỉ số 0
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedOptionIndex == 0
                                      ? Colors.black
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/paypal.png',
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Paypal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () => toggleSelection(1),
                              // Gọi hàm với chỉ số 1
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedOptionIndex == 1
                                      ? Colors.black
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),


                  Container(

                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề chi tiết thanh toán
                        Text(
                          'Chi tiết thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Tổng tiền hàng
                        Text(
                          'Tổng tiền hàng: ${formatCurrency.format(totalPrice)}đ',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),

                        // Phí vận chuyển
                        Text(
                          'Tổng phí vận chuyển: ${formatCurrency.format(shippingFee)}đ',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),

                        // Mã giảm giá
                        Text(
                          'Mã giảm giá: ${formatCurrency.format(discount)}đ',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),

                        // Tổng thanh toán
                        Text(
                          'Tổng thanh toán: ${formatCurrency.format(totalPayment)}đ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),                ],
              )),


              Container(

                padding: const EdgeInsets.all(10.0),
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
                        'Tổng tiền: ${formatCurrency.format(totalPayment)}đ',
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
                          onPressed: handlePayment, // Gọi hàm xử lý thanh toán
                          child: Text(
                            'Thanh toán',
                            style: TextStyle(
                                color: Colors.white), // Đặt màu chữ thành trắng
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blueGrey, // Đặt màu nền thành xanh
                          ),
                        )),
                  ],
                ),
              ),
            ]),
    );
  }
}
