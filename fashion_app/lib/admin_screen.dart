import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'login_screen.dart';


class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final formatCurrency = NumberFormat("#,##0", "vi_VN");


  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('images/$fileName');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageReference.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _addProduct(
      String name,
      int price,
      String description,
      String category,
      List<String> colors,
      List<String> sizes,
      List<String>? imageUrls, // Accepts a list of image URLs
      ) async {
    List<String> finalImageUrls = [];

    // If there are image URLs passed from the dialog, add them to the list
    if (imageUrls != null && imageUrls.isNotEmpty) {
      finalImageUrls.addAll(imageUrls);
    }

    // If an image has been picked, upload it and add its URL to the list
    if (_image != null) {
      String uploadedImageUrl = await _uploadImage(_image!);
      finalImageUrls.add(uploadedImageUrl);
    }

    // Check if finalImageUrls is empty
    if (finalImageUrls.isEmpty) {
      return; // Don't add the product if there are no images
    }

    List<String> keywords = name.toLowerCase().split(' ');

    // Add the product to Firestore
    await _firestore.collection('products').add({
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'colors': colors,
      'sizes': sizes,
      'createdAt': FieldValue.serverTimestamp(),
      'images': finalImageUrls, // Store the list of images
      'productId': _firestore.collection('products').doc().id,
      'keywords': keywords, // Mảng các từ khóa

    });
  }



  Future<void> _updateProduct(String productId, String name, int price, String description) async {
    await _firestore.collection('products').doc(productId).update({
      'name': name,
      'price': price,
    });
  }

  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }


  Future<List<Map<String, dynamic>>> _fetchAllUsersOrders() async {
    try {
      // Lấy tất cả người dùng từ collection 'users'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> orders = [];

      // Duyệt qua tất cả người dùng và lấy thông tin đơn hàng
      for (var doc in querySnapshot.docs) {
        var orderHistory = doc['orderHistory'] as List;

        // Duyệt qua lịch sử đơn hàng của mỗi người dùng
        for (var order in orderHistory) {
          orders.add({
            'userId': doc.id,  // ID người dùng
            'orderId': order['orderId'],  // orderId
            'orderDate': order['orderDate'],  // Ngày đặt hàng
            'isCompleted': order['isCompleted'] ?? false,  // Trạng thái hoàn thành
            'isCancelled': order['isCancelled'] ?? false,  // Trạng thái hủy
          });
        }
      }

      return orders;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu đơn hàng: $e');
      return []; // Trả về danh sách rỗng nếu có lỗi
    }
  }

  Future<void> updateOrderStatus(String orderId, {bool isCompleted = false, bool isCancelled = false}) async {
    var usersRef = FirebaseFirestore.instance.collection('users');

    // Lấy tất cả người dùng từ Firestore
    var querySnapshot = await usersRef.get();

    // Duyệt qua tất cả các tài liệu người dùng
    for (var doc in querySnapshot.docs) {
      var ordersData = doc.data() as Map<String, dynamic>;
      var orderHistory = ordersData['orderHistory'] as List<dynamic>?;

      // Nếu orderHistory là null, bỏ qua tài liệu này
      if (orderHistory == null) {
        continue;
      }

      // Tạo bản sao của orderHistory để cập nhật
      List<dynamic> updatedOrderHistory = List.from(orderHistory);

      // Tìm đơn hàng cần cập nhật trong bản sao
      bool orderFound = false;
      for (int i = 0; i < updatedOrderHistory.length; i++) {
        if (updatedOrderHistory[i]['orderId'] == orderId) {
          // Cập nhật các trạng thái theo logic mong muốn
          updatedOrderHistory[i] = {
            ...updatedOrderHistory[i],
            'isCompleted': isCompleted,
            'isCancelled': isCancelled,
            'isGoing': !(isCompleted || isCancelled),  // 'isGoing' là true nếu cả hai cái kia là false
          };
          orderFound = true;
          break;
        }
      }

      if (orderFound) {
        // Cập nhật lại tài liệu với mảng orderHistory đã thay đổi
        await doc.reference.update({'orderHistory': updatedOrderHistory});
        print("Đơn hàng đã được cập nhật!");
        return; // Thoát hàm sau khi cập nhật thành công
      }
    }

    print("Không tìm thấy đơn hàng với orderId: $orderId");
  }







  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: ListTile(
                title: Text(
                  product['name'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text('Giá: ${formatCurrency.format(product['price'])}đ'),
                leading: product['images'] is List && product['images'].isNotEmpty
                    ? Image.network(product['images'][0], width: 50, fit: BoxFit.cover)
                    : Icon(Icons.image),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(product.id),
                ),
                onTap: () {
                  _showEditProductDialog(product.id, product['name'], product['price'], product['description']);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(String productId, String currentName, int currentPrice, String currentDescription) {
    final nameController = TextEditingController(text: currentName);
    final priceController = TextEditingController(text: currentPrice.toString());
    final descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa sản phẩm'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) { // Use StatefulBuilder
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Giá'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Mô tả'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setDialogState(() {
                          // Force the dialog to rebuild after picking an image
                        });
                      },
                      child: Text('Chọn ảnh'),
                    ),
                    if (_image != null)
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    _image = null; // Xóa ảnh
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateProduct(
                  productId,
                  nameController.text,
                  int.parse(priceController.text),
                  descriptionController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildOrderList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUsersOrders(), // Lấy tất cả đơn hàng
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Có lỗi xảy ra'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Không có đơn hàng'));
        } else {
          List<Map<String, dynamic>> orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              String orderId = order['orderId']; // Lấy orderId
              var orderDate = order['orderDate']; // Lấy orderDate

              // Chuyển đổi Timestamp sang DateTime
              String formattedDate = '';
              if (orderDate is Timestamp) {
                DateTime dateTime = orderDate.toDate();
                formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
              } else {
                formattedDate = orderDate.toString();
              }

              bool isCompleted = order['isCompleted'] ?? false;
              bool isCancelled = order['isCancelled'] ?? false;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCompleted)
                        Text(
                          'Đơn đã hoàn thành',
                          style: TextStyle(color: Colors.green, fontSize: 14),
                        )
                      else if (isCancelled)
                        Text(
                          'Đơn đã huỷ',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        )
                      else
                        Text(
                          'Đơn đang xử lý',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      Text(
                        'Mã đơn hàng: $orderId',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Ngày đặt hàng: $formattedDate',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: isCompleted || isCancelled
                            ? null
                            : () {
                          setState(() {
                            updateOrderStatus(orderId, isCompleted: true); // Hoàn thành đơn hàng
                            order['isCompleted'] = true; // Cập nhật ngay lập tức
                            order['isCancelled'] = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: isCompleted || isCancelled
                            ? null
                            : () {
                          setState(() {
                            updateOrderStatus(orderId, isCancelled: true); // Cập nhật qua API
                            order['isCompleted'] = false;
                            order['isCancelled'] = true; // Cập nhật ngay lập tức
                          });

                          Future.delayed(Duration(milliseconds: 5000), () {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false, // Xóa icon mũi tên
          title: Text(
            'Bảng điều khiển Admin',
            style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: Colors.blue, // Màu của indicator khi tab được chọn
            labelColor: Colors.white, // Màu chữ khi tab được chọn
            unselectedLabelColor: Colors.grey, // Màu chữ khi tab không được chọn
            tabs: [
              Tab(text: 'Quản lý sản phẩm'),
              Tab(text: 'Quản lý đơn hàng'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout), // Icon đăng xuất
              color: Colors.white,

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),

        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _showAddProductDialog();
                    },
                    child: Text('Thêm sản phẩm mới'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildProductList()),
              ],
            ),
            Expanded(child: _buildOrderList()),

          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imagesController = TextEditingController(); // This will hold a comma-separated string of image URLs
    final categoryController = TextEditingController();
    final colorsController = TextEditingController();
    final sizesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm sản phẩm mới'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Giá'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(labelText: 'Danh mục'),
                    ),
                    TextField(
                      controller: colorsController,
                      decoration: InputDecoration(labelText: 'Màu sắc (ngăn cách bằng dấu phẩy)'),
                    ),
                    TextField(
                      controller: sizesController,
                      decoration: InputDecoration(labelText: 'Kích thước (ngăn cách bằng dấu phẩy)'),
                    ),
                    TextField(
                      controller: imagesController,
                      decoration: InputDecoration(labelText: 'Dán URL ảnh (ngăn cách bằng dấu phẩy)'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setDialogState(() {
                          // Force the dialog to rebuild after picking an image
                        });
                      },
                      child: Text('Chọn ảnh'),
                    ),
                    if (_image != null)
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    _image = null; // Xóa ảnh
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Split the image URLs into a list
                List<String> imageUrls = imagesController.text.split(',')
                    .map((url) => url.trim())
                    .where((url) => url.isNotEmpty) // Remove any empty entries
                    .toList();

                _addProduct(
                  nameController.text,
                  int.parse(priceController.text),
                  '', // Assuming you will set the product description here if needed
                  categoryController.text,
                  colorsController.text.split(',').map((color) => color.trim()).toList(),
                  sizesController.text.split(',').map((size) => size.trim()).toList(),
                  imageUrls, // Pass the list of image URLs here
                );
                Navigator.pop(context);
              },
              child: Text('Thêm'),
            ),
          ],
        );
      },
    );
  }
}
