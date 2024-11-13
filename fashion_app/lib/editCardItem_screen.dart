import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/BottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UpdateCartItemPage extends StatefulWidget {
  final Map<String, dynamic> cartItem; // Thông tin sản phẩm trong giỏ hàng

  const UpdateCartItemPage({Key? key, required this.cartItem}) : super(key: key);

  @override
  _UpdateCartItemPageState createState() => _UpdateCartItemPageState();
}

class _UpdateCartItemPageState extends State<UpdateCartItemPage> {
  int _quantity = 1; // Khởi tạo với giá trị mặc định là 1
  int? _selectedSize; // Kích thước được chọn
  int? _selectedColor; // Màu sắc được chọn
  List<String> sizes = []; // Danh sách kích thước
  List<String> colors = []; // Danh sách màu sắc
  List<String> images = []; // Danh sách màu sắc

  final formatCurrency = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    _quantity = widget.cartItem['quantity']; // Khởi tạo số lượng từ giỏ hàng

    // Lấy thông tin kích thước và màu sắc từ Firestore dựa trên productId
    _fetchProductDetails(widget.cartItem['name']);
  }

  Future<void> _fetchProductDetails(String name) async {
    print('Fetching product details for productId: $name'); // Debug statement
    try {
      QuerySnapshot productQuerySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: name) // Truy vấn theo trường productId
          .get();

      if (productQuerySnapshot.docs.isNotEmpty) {
        // Nếu tìm thấy ít nhất một document
        DocumentSnapshot productSnapshot = productQuerySnapshot.docs.first; // Lấy document đầu tiên
        print('Product found: ${productSnapshot.data()}'); // Debug statement
        setState(() {
          sizes = List<String>.from(productSnapshot.get('sizes') ?? []);
          colors = List<String>.from(productSnapshot.get('colors') ?? []);
          images = List<String>.from(productSnapshot.get('images') ?? []);

          // Gán kích thước và màu sắc đã chọn từ cartItem nếu có
          _selectedSize = sizes.indexWhere((size) => size == (widget.cartItem['sizes'] as String?));
          _selectedColor = colors.indexWhere((color) => color == (widget.cartItem['colors'] as String?));
        });
      } else {
        print('Product not found for name: $name'); // Debug statement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sản phẩm không tồn tại.')),
        );
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin sản phẩm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi tải thông tin sản phẩm.')),
      );
    }
  }

  Future<void> _updateCart() async {
    // Lấy uid của người dùng hiện tại
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Người dùng chưa đăng nhập!')),
      );
      return; // Thoát hàm nếu người dùng chưa đăng nhập
    }

    String userId = currentUser.uid; // Lấy uid của người dùng hiện tại

    // Tham chiếu tới document của người dùng trong Firestore
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      // Lấy dữ liệu giỏ hàng hiện tại của người dùng
      DocumentSnapshot userSnapshot = await userDoc.get();
      List<dynamic> cart = userSnapshot.get('cart') ?? [];

      // Cập nhật sản phẩm trong giỏ hàng
      for (var item in cart) {
        if (item['productId'] == widget.cartItem['productId']) {
          item['quantity'] = _quantity; // Cập nhật số lượng
          item['sizes'] = sizes[_selectedSize!]; // Cập nhật kích thước
          item['colors'] = colors[_selectedColor!]; // Cập nhật màu sắc
          break;
        }
      }

      // Cập nhật giỏ hàng của người dùng trong Firestore
      await userDoc.update({
        'cart': cart,
      });

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật giỏ hàng!')),
      );
    } catch (e) {
      print('Lỗi khi cập nhật giỏ hàng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi cập nhật giỏ hàng.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        title: Text(
          "Cập nhật giỏ hàng",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                height: 350.h,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Kiểm tra cử chỉ tap (tuỳ chọn)
                        print("Tapped image at index: $index");
                      },
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: EdgeInsets.all(10.0), // Đặt khoảng cách bên trong Container
                decoration: BoxDecoration(
                  color: Colors.grey[900], // Màu nền cho Container
                  borderRadius: BorderRadius.circular(12), // Bo góc
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cartItem['name'],
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${formatCurrency.format(widget.cartItem['price'])}đ',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.red),
                    ),

                    Text('Kích thước', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                    Wrap(
                      spacing: 8.0,
                      children: List.generate(sizes.length, (index) {
                        return ChoiceChip(
                          label: Text(sizes[index]),
                          selected: _selectedSize == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSize = selected ? index : null;
                            });
                          },
                          selectedColor: Colors.blueGrey,
                          backgroundColor: Colors.white,
                        );
                      }),
                    ),

                    Text('Màu sắc', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                    Wrap(
                      spacing: 8.0,
                      children: List.generate(colors.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = index;
                            });
                          },
                          child: Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getColor(colors[index]),
                              border: Border.all(
                                color: _selectedColor == index ? Colors.blueGrey : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượng', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 1) _quantity--;
                                });
                              },
                            ),
                            Text('$_quantity', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // Nút "Cập nhật giỏ hàng"
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateCart();
                    Navigator.pop(context, true); // Trả về true khi cập nhật thành công
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: Text(
                    'Cập nhật giỏ hàng',
                    style: TextStyle(fontSize: 18.sp, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }



  // Hàm lấy màu sắc dựa trên chuỗi
  Color _getColor(String colorName) {
    switch (colorName) {
      case "Red":
        return Colors.red;
      case "Blue":
        return Colors.blue;
      case "Black":
        return Colors.black;
      case "White":
        return Colors.white;
      case "Navy":
        return Color(0xFF000080);
      default:
        return Colors.grey;
    }
  }
}
