import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Lịch sử đơn hàng',style: TextStyle(color: Colors.white),),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Mũi tên back màu trắng
            onPressed: () {
              Navigator.pop(context);  // Quay lại trang trước
            },
          ),
          centerTitle: true,  // Căn giữa title
          bottom: TabBar(
            indicatorColor: Colors.blue, // Màu của indicator khi tab được chọn
            labelColor: Colors.white, // Màu chữ khi tab được chọn
            unselectedLabelColor: Colors.grey, // Màu chữ khi tab không được chọn
            tabs: [
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã giao'),
              Tab(text: 'Hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OrderStatusList(status: 'Đang giao'),
            OrderStatusList(status: 'Đã giao'),
            OrderStatusList(status: 'Hủy'),
          ],
        ),
      ),
    );
  }
}

class OrderStatusList extends StatelessWidget {
  final String status;

  const OrderStatusList({required this.status});

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      List<Map<String, dynamic>> orderHistory =
      List<Map<String, dynamic>>.from(userDoc.get('orderHistory') ?? []);

      if (status == 'Đang giao') {
        return orderHistory.where((order) => order['isGoing'] == true).toList();
      } else if (status == 'Đã giao') {
        return orderHistory.where((order) => order['isCompleted'] == true).toList();
      } else if (status == 'Hủy') {
        return orderHistory.where((order) => order['isCancelled'] == true).toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Không có đơn hàng nào.'));
        }

        final orders = snapshot.data!;

        return  Scaffold(
          backgroundColor: Colors.white70,
          body: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            DateTime orderDate = (order['orderDate'] as Timestamp).toDate();
            String formattedDate =
            DateFormat('dd-MM-yyyy HH:mm').format(orderDate);

            return Card(
              color: Colors.white,
              margin: EdgeInsets.all(10),
              child: ListTile(
                leading: Icon(
                  Icons.local_shipping,
                  color: status == 'Đã giao'
                      ? Colors.green
                      : status == 'Hủy'
                      ? Colors.red
                      : Colors.orange,
                ),
                title: Text('Mã đơn hàng: ${order['orderId']}'),
                subtitle: Text('Ngày đặt: $formattedDate'),
                trailing: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Đã giao'
                        ? Colors.green
                        : status == 'Hủy'
                        ? Colors.red
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Điều hướng đến trang chi tiết đơn hàng
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(orderId: order['orderId']),
                    ),
                  );
                },
              ),
            );
          },
          ),
        );
      },
    );
  }
}

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  OrderDetailPage({required this.orderId});

  Future<Map<String, dynamic>?> _fetchOrderDetails() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      List<Map<String, dynamic>> orderHistory =
      List<Map<String, dynamic>>.from(userDoc.get('orderHistory') ?? []);

      // Find order by orderId
      return orderHistory.firstWhere(
            (order) => order['orderId'] == orderId,
        orElse: () => {},
      );
    }
    return null;
  }

  // Format currency
  final formatCurrency = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchOrderDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Không tìm thấy thông tin đơn hàng.'));
        }

        final order = snapshot.data!;
        DateTime orderDate = (order['orderDate'] as Timestamp).toDate();
        String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(orderDate);


        double totalPrice = order['cart'].fold(0.0, (sum, item) {
          return sum + (item['price'] is int ? (item['price'] as int).toDouble() : item['price']) * (item['quantity'] as int);
        });


        // Phí vận chuyển và mã giảm giá mặc định
        double shippingFee = 15000.0;  // Mặc định 15.000đ
        double discount = 0.0;  // Mặc định 0đ

        // Tính tổng thanh toán
        double totalPayment = totalPrice - shippingFee - discount;

        final formatCurrency = NumberFormat("#,##0", "vi_VN");

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              'Chi tiết đơn hàng',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white), // Mũi tên back màu trắng
              onPressed: () {
                Navigator.pop(context);  // Quay lại trang trước
              },
            ),
            centerTitle: true,  // Căn giữa title
          ),

          body: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),  // Thêm một chút padding để nội dung không dính vào viền
                  decoration: BoxDecoration(
                    color: Colors.white,  // Màu nền của container
                    borderRadius: BorderRadius.circular(10),  // Bo tròn với bán kính 10
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),  // Màu bóng mờ của shadow
                        offset: Offset(0, 4),  // Vị trí của shadow
                        blurRadius: 8,  // Làm mờ shadow
                        spreadRadius: 1,  // Phát tán shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đơn hàng: ${order['orderId']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  // Thêm style cho văn bản
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ngày đặt: $formattedDate',
                        style: TextStyle(fontSize: 14, color: Colors.grey),  // Thêm style cho ngày đặt
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),  // Thêm một chút padding để nội dung không dính vào viền
                  decoration: BoxDecoration(
                    color: Colors.white,  // Màu nền của container
                    borderRadius: BorderRadius.circular(10),  // Bo tròn với bán kính 10
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),  // Màu bóng mờ của shadow
                        offset: Offset(0, 4),  // Vị trí của shadow
                        blurRadius: 8,  // Làm mờ shadow
                        spreadRadius: 1,  // Phát tán shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order['name']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  // Thêm style cho văn bản
                      ),
                      Text(
                        ' (${order['phone']})',
                        style: TextStyle(fontSize: 16, color: Colors.grey),  // Thêm style cho ngày đặt
                      ),
                      ]
                  ),
                      SizedBox(height: 8),
                      Text(
                        'Địa chỉ: ${order['address']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),  // Thêm style cho ngày đặt
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),

                Container(
                  margin: EdgeInsets.symmetric(vertical: 0.0),
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
                    children: [
                      // Lặp qua danh sách 'cart' và tạo widget cho từng sản phẩm
                      ...order['cart'].map((item) {
                        return GestureDetector(
                          onTap: () {
                            // Handle item tap, if needed
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
                                            Text('Size: ${item['sizes']}'),
                                            const SizedBox(width: 85),
                                            Text('Màu sắc:'),
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: _getColor(item['colors']),  // Dùng hàm để lấy màu
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _getColor(item['colors']) == Colors.white ? Colors.black : Colors.white,  // Màu viền phù hợp
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
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(5.0),
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
                ),
              ],
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  // Hàm chuyển chuỗi màu sắc thành màu cụ thể
  Color _getColor(String colorName) {
    switch (colorName) {
      case 'White':
        return Colors.white;
      case 'Black':
        return Colors.black;
      case 'Navy':
        return Color(0xFF000080);  // Mã hex màu Navy
      case 'Red':
        return Colors.red;
      case 'Green':
        return Colors.green;
      case 'Blue':
        return Colors.blue;
    // Thêm các màu khác nếu cần
      default:
        return Colors.grey;  // Màu mặc định nếu không có tên màu phù hợp
    }
  }
}


