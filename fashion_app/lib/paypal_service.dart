import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalService {
  final String clientId = 'AVDxp1BbjfLp-CmdrBG5MEsf0bcNZvwWjHKy-OgOkDVXInEGbow27MpMziGP4h8pc4U33Lk55OV1B2n1'; // Thay thế bằng Client ID của bạn
  final String secret = 'EJndgS23EGexwrsHibS71uOT3U9NC3aEMnNJlB5k2IFgaxQs6LSZunVfQiBX8kLn_iWFKnnkfSj0mWFQ'; // Thay thế bằng Secret của bạn
  final String baseUrl = 'https://api.sandbox.paypal.com'; // Sử dụng sandbox cho thử nghiệm

  Future<String?> getAccessToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/oauth2/token'),
      headers: {
        'Accept': 'application/json',
        'Accept-Language': 'en_US',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$clientId:$secret')),
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['access_token']; // Trả về access token
    } else {
      // Xử lý lỗi
      print('Failed to get access token: ${response.body}');
      return null;
    }
  }

  Future<String?> createPayment(String accessToken, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/payments/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Sử dụng Bearer token
      },
      body: jsonEncode({
        "intent": "sale",
        "payer": {
          "payment_method": "paypal",
        },
        "transactions": [
          {
            "amount": {
              "total": amount.toString(),
              "currency": "USD",
            },
            "description": "Payment for your order.",
          }
        ],
        "redirect_urls": {
          "return_url": "https://your-website.com/success",
          "cancel_url": "https://your-website.com/cancel",
        }
      }),
    );

    if (response.statusCode == 201) {
      final payment = jsonDecode(response.body);
      print('Payment created successfully: ${payment['id']}');
      return payment['id']; // Trả về ID thanh toán
    } else {
      print('Failed to create payment: ${response.body}');
      return null; // Trả về null nếu không thành công
    }
  }
}
