import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

import 'package:intl/intl.dart';

import 'categoryProduct_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentIndex = 0;
  int cartItemCount = 0;

  final List<String> _imageUrls = [];
  final List<String> _categoryImages = [];
  final List<DocumentSnapshot> _products = [];
  final List<Map<String, dynamic>> cartItems = [];


  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadCategoryImages();
    _loadProducts(); // Tải sản phẩm
    _startAutoSlide();
  }



  Future<void> _loadProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _products.addAll(snapshot.docs); // Thêm sản phẩm vào danh sách
    });
  }

  Future<void> _loadImages() async {
    final storage = FirebaseStorage.instance;
    final List<String> imageNames = [
      'banner1.jpg',
      'banner2.jpg',
      'banner3.jpg',
      'banner4.jpg',
    ];

    for (String imageName in imageNames) {
      String path = 'banner/$imageName';
      String url = await storage.ref(path).getDownloadURL();
      _imageUrls.add(url);
    }

    setState(() {});
  }

  Future<void> _loadCategoryImages() async {
    final storage = FirebaseStorage.instance;
    final List<String> categoryNames = [
      'shirt.png',
      'pant.png',
      'shoe.png',
      'sandal.png',
      'cap.png',
      'bag.png',
      'glasses.png',
    ];

    for (String categoryName in categoryNames) {
      String path = 'icon/$categoryName'; // Đường dẫn tới ảnh category
      String url = await storage.ref(path).getDownloadURL();
      _categoryImages.add(url);
    }

    setState(() {});
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_imageUrls.isNotEmpty) {
        if (_currentIndex < _imageUrls.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    if (_imageUrls.isEmpty || _categoryImages.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Bỏ icon back
        title: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Tìm kiếm sản phẩm...",
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white), // Icon màu trắng
            onPressed: () {
              String searchTerm = _searchController.text;
              if (searchTerm.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryProductPage(
                      category: 'search',
                      searchTerm: searchTerm, // Truyền từ khóa tìm kiếm
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),

      backgroundColor: const Color(0xFF232323), // Màu nền #232323
      body: ListView(
        children: [
          // Thanh PageView hiển thị banner
          Container(
            height: 200.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _imageUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),


          // Thanh Category
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF363636),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              margin: EdgeInsets.only(top: 10.h),
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                      onTap: () {
                    // Điều hướng sang trang hiển thị sản phẩm theo category
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CategoryProductPage(category: ['Shirt', 'Pant', 'Shoes', 'Slipper', 'Cap', 'Bag', 'Glasses'][index]),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0); // Hiệu ứng vuốt từ phải sang trái
                          const end = Offset.zero;
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Color(0xFF454444),
                            borderRadius: BorderRadius.circular(10), // Bo tròn góc
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1), // Màu bóng
                                spreadRadius: 2, // Bán kính lan rộng của bóng
                                blurRadius: 6,   // Độ mờ của bóng
                                offset: Offset(0, 3), // Độ lệch của bóng (0 ngang, 3 dọc)
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10), // Bo tròn góc cho hình ảnh
                            child: Image.network(
                              _categoryImages[index],
                              fit: BoxFit.cover, // Hình ảnh vừa khít trong container
                            ),
                          ),
                        ),

                        SizedBox(height: 5.h),
                        Text(
                          ['Áo', 'Quần', 'Giày', 'Dép', 'Mũ', 'Túi', 'Kính'][index],
                          style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 15.0),  // Cách trái 10 đơn vị
            child: Text(
              'Gợi ý hôm nay',
              style: TextStyle(
                color: Colors.white,  // Màu chữ trắng
                fontWeight: FontWeight.bold,  // In đậm
                fontSize: 20,  // Kích thước font
              ),
            ),
          ),
          SizedBox(height: 10,),
          // Hiển thị danh sách sản phẩm
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.h,
                mainAxisSpacing: 10.h,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                var product = _products[index].data() as Map<String, dynamic>;
                String imageUrl = (product['images'] is List && product['images'].isNotEmpty) ? product['images'][0] : '';
                String name = product['name'] ?? 'Tên sản phẩm';
                double price = (product['price'] is int) ? (product['price'] as int).toDouble() : (product['price'] as double? ?? 0.0);

                // Sử dụng NumberFormat để định dạng giá tiền
                final formatCurrency = NumberFormat("#,##0", "vi_VN");

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ProductDetail(product: product),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF363636),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error);
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                '${formatCurrency.format(price)}đ', // Hiển thị giá có dấu chấm
                                style: TextStyle(fontSize: 14.sp, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 90.h)
        ],
      ),
    );
  }
}
