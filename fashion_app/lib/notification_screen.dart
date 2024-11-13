import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  // Danh sách thông báo mẫu
  final List<Map<String, String>> notifications = [
    {
      'title': 'Giảm giá mùa thu!',
      'message': 'Đừng bỏ lỡ cơ hội mua sắm với giá ưu đãi lên đến 50%',
      'date': '12/11/2024',
    },
    {
      'title': 'Sản phẩm mới',
      'message': 'Khám phá bộ sưu tập áo khoác mùa đông mới nhất',
      'date': '10/11/2024',
    },
    {
      'title': 'Flash Sale',
      'message': 'Giảm giá cực sốc trong 24 giờ tới, hãy nhanh tay!',
      'date': '08/11/2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
        Text('Thông báo', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var notification = notifications[index];

            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 5,
              child: ListTile(
                contentPadding: EdgeInsets.all(10.w),
                title: Text(
                  notification['title']!,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5.h),
                    Text(
                      notification['message']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Ngày: ${notification['date']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 30.w,
                ),
                onTap: () {
                  // Thực hiện hành động khi nhấn vào thông báo (ví dụ: đi đến trang chi tiết)
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
