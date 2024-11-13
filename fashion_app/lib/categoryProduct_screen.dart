import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryProductPage extends StatelessWidget {
  final String category;
  final String? searchTerm;

  CategoryProductPage({required this.category, this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('$category', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: (searchTerm != null && searchTerm!.isNotEmpty)
            ? FirebaseFirestore.instance
            .collection('products')
            .where('keywords', arrayContains: searchTerm!.toLowerCase())
            .get()
            : FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: category)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Nếu có lỗi, hiển thị thông báo lỗi trong log và UI
            print('Error: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi! ${snapshot.error}', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Kiểm tra xem có dữ liệu không
            print('No products found for search term: $searchTerm');
            return Center(
              child: Text(
                'Không có sản phẩm nào!',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          var _products = snapshot.data!.docs;


          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 3 / 4,
            ),
            itemBuilder: (context, index) {
              var product = _products[index].data() as Map<String, dynamic>;
              String imageUrl = (product['images'] is List && product['images'].isNotEmpty)
                  ? product['images'][0]
                  : '';
              String name = product['name'] ?? 'Tên sản phẩm';
              double price = (product['price'] is int)
                  ? (product['price'] as int).toDouble()
                  : (product['price'] as double? ?? 0.0);

              final formatCurrency = NumberFormat("#,##0", "vi_VN");

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductDetail(product: product),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
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
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5.0),
                            Text(
                              '${formatCurrency.format(price)}đ',
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

