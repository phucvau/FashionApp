import 'package:fashion_app/BottomNavBar.dart';
import 'package:fashion_app/orderHistory_screen.dart';
import 'package:flutter/material.dart';

class ConfirmedOrderScreen extends StatelessWidget {
  const ConfirmedOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Đặt hàng thành công',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Ẩn icon back
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              'Đơn hàng của bạn đã được xác nhận!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Cảm ơn bạn đã mua sắm cùng chúng tôi.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Nút Xem lịch sử đơn hàng
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BottomNavBar(cart: [],)),
                );
                },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                side: BorderSide(color: Colors.white),
                backgroundColor: Colors.blueGrey,
              ),
              child: Text(
                'Trang chủ',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
