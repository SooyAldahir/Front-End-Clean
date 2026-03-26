import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpService {
  static const _baseUrl     = 'https://api-otp.app.syswork.online/api/v1';
  static const _serviceEmail    = 'irving.patricio@ulv.edu.mx';
  static const _servicePassword = 'irya0904';

  Future<String> _authenticate() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _serviceEmail, 'password': _servicePassword}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['token'].toString();
    throw Exception('Fallo la autenticación del servicio OTP.');
  }

  Future<void> sendOtp(String userEmail) async {
    final token = await _authenticate();
    final res = await http.post(
      Uri.parse('https://api-otp.app.syswork.online/api/v1/otp_app/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'x-access-token': token,
      },
      body: jsonEncode({
        'email': userEmail,
        'subject': 'Verificacion de Email',
        'message': 'Verifica tu email con el codigo de abajo',
        'duration': 1,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Error al enviar OTP (${res.statusCode})');
    }
  }

  Future<bool> verifyOtp(String userEmail, String otpCode) async {
    try {
      final token = await _authenticate();
      final res = await http.post(
        Uri.parse('$_baseUrl/email_verification/verifyOTP'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
        body: jsonEncode({'email': userEmail, 'otp': otpCode}),
      );
      if (res.statusCode == 200) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}
