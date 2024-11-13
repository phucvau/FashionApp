import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/BottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ProductDetail extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetail({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailState createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int _quantity = 1; // Số lượng sản phẩm
  int? _selectedSize; // Kích thước được chọn
  int? _selectedColor; // Màu sắc được chọn
  List<String> colors = [];
  List<String> sizes = [];

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(widget.product['images']); // Danh sách hình ảnh
    String name = widget.product['name'] ?? 'Tên sản phẩm';
    int price = widget.product['price'] ?? 0; // Lấy giá tiền dưới dạng số
    List<String> sizes = List<String>.from(widget.product['sizes']);
    colors = List<String>.from(widget.product['colors']); // Cập nhật colors

    final formatCurrency = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: const Color(0xFF232323), // Màu nền #232323
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323), // Màu nền #232323
        title: Text(
          "Chi tiết sản phẩm",
          style: TextStyle(color: Colors.white), // Màu chữ của tiêu đề
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Màu của nút back
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hiển thị hình ảnh
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

            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị giá tiền ngay phía trên tên sản phẩm
                  Text('${formatCurrency.format(price)}đ', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(name, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),

                  // Hiển thị kích thước
                  Text('Kích thước', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(sizes.length, (index) {
                      return ChoiceChip(
                        label: Text(sizes[index]),
                        selected: _selectedSize == index,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSize = selected ? index : null; // Lưu kích thước được chọn
                          });
                        },
                        selectedColor: Colors.blueGrey,
                        backgroundColor: Colors.white,
                      );
                    }),
                  ),

                  // Hiển thị màu sắc
                  Text('Màu sắc', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(colors.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = index; // Lưu màu sắc được chọn
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

                  // Hiển thị số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số lượng', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.white,),
                            onPressed: () {
                              setState(() {
                                if (_quantity > 1) _quantity--; // Giảm số lượng
                              });
                            },
                          ),
                          Text('$_quantity', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white,),
                            onPressed: () {
                              setState(() {
                                _quantity++; // Tăng số lượng
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Nút "Thêm vào giỏ hàng"
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Xử lý thêm vào giỏ hàng và chờ cho đến khi hoàn tất
                        await _addToCart();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BottomNavBar(cart: []), // Pass the initial cart (an empty list in this case)
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h), backgroundColor: Colors.blueGrey,
                      ),
                      child: Text(
                        'Thêm vào giỏ hàng',
                        style: TextStyle(fontSize: 18.sp, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final uuid = Uuid(); // Khởi tạo đối tượng Uuid

    // Lấy uid của người dùng hiện tại
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Người dùng chưa đăng nhập!')),
      );
      return; // Thoát hàm nếu người dùng chưa đăng nhập
    }

    String userId = currentUser.uid; // Lấy uid của người dùng hiện tại

    // Lấy productId từ widget.product
    String productId = uuid.v4(); // Tạo productId ngẫu nhiên

    int quantity = _quantity; // Lấy số lượng hiện tại
    String selectedSize = _selectedSize != null ? widget.product['sizes'][_selectedSize!] : ''; // Lấy giá trị kích thước thực tế
    String selectedColor = _selectedColor != null ? colors[_selectedColor!] : ''; // Lấy giá trị màu sắc thực tế

    // Lấy tên, hình ảnh và giá sản phẩm
    String productName = widget.product['name']; // Lấy tên sản phẩm
    String productImage = (widget.product['images'] is List && widget.product['images'].isNotEmpty)
        ? widget.product['images'][0] // Lấy hình ảnh sản phẩm (giả sử là ảnh đầu tiên)
        : '';
    int productPrice = widget.product['price'];

    // Tham chiếu tới document của người dùng trong Firestore
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      // Lấy dữ liệu giỏ hàng hiện tại của người dùng
      DocumentSnapshot userSnapshot = await userDoc.get();
      List<dynamic> cart = userSnapshot.get('cart') ?? [];

      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      bool productExists = false;
      for (var item in cart) {
        if (item['name'] == productName && item['sizes'] == selectedSize && item['colors'] == selectedColor) {
          item['quantity'] += quantity; // Tăng số lượng sản phẩm lên
          productExists = true;
          break;
        }
      }

      // Nếu sản phẩm chưa có trong giỏ hàng, thêm sản phẩm mới
      if (!productExists) {
        cart.add({
          'productId': productId, // Sử dụng productId từ sản phẩm
          'quantity': quantity,
          'sizes': selectedSize, // Cập nhật kích thước thực tế
          'colors': selectedColor,
          'name': productName, // Thêm tên sản phẩm vào giỏ hàng
          'images': productImage, // Thêm hình ảnh sản phẩm vào giỏ hàng
          'price': productPrice, // Thêm giá sản phẩm vào giỏ hàng
        });
      }

      // Cập nhật giỏ hàng của người dùng trong Firestore
      await userDoc.update({
        'cart': cart,
      });

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm sản phẩm vào giỏ hàng thành công!')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi thêm sản phẩm vào giỏ hàng!')),
      );
    }
  }



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
    // Bạn có thể thêm màu khác nếu cần
      default:
        return Colors.grey;
    }
  }
}

