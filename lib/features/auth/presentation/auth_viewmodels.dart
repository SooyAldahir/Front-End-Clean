import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/auth_repository.dart';
import '../../../core/utils/otp_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'dart:convert';

// ─── LoginViewModel ───────────────────────────────────────────────────────────
class LoginViewModel {
  final AuthRepository _repo = AuthRepository();

  final emailCtrl   = TextEditingController();
  final passCtrl    = TextEditingController();
  final loading     = ValueNotifier<bool>(false);

  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    loading.dispose();
  }

  Future<String?> login() async {
    final loginId  = emailCtrl.text.trim();
    final password = passCtrl.text;
    if (loginId.isEmpty || password.isEmpty) return 'Ingresa usuario y contraseña';

    loading.value = true;
    try {
      final user = await _repo.login(loginId, password);
      return null; // null = éxito
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }
}

// ─── ForgotPasswordViewModel ──────────────────────────────────────────────────
class ForgotPasswordViewModel {
  final AuthRepository _repo    = AuthRepository();
  final OtpService     _otp     = OtpService();

  final emailCtrl = TextEditingController();
  final otpCtrl   = TextEditingController();
  final passCtrl  = TextEditingController();
  final step      = ValueNotifier<int>(0);
  final loading   = ValueNotifier<bool>(false);

  void dispose() {
    emailCtrl.dispose();
    otpCtrl.dispose();
    passCtrl.dispose();
    step.dispose();
    loading.dispose();
  }

  bool isPasswordValid(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p) &&
      RegExp(r'[!"#\$%&/\(\)=\?\.,@]').hasMatch(p);

  Future<String?> sendOtp() async {
    if (emailCtrl.text.trim().isEmpty) return 'Ingresa tu correo';
    loading.value = true;
    try {
      await _otp.sendOtp(emailCtrl.text.trim());
      step.value = 1;
      return null;
    } catch (_) {
      return 'Error al enviar código. Verifica tu correo.';
    } finally {
      loading.value = false;
    }
  }

  Future<String?> verifyOtp() async {
    if (otpCtrl.text.trim().isEmpty) return 'Ingresa el código';
    loading.value = true;
    try {
      final valid = await _otp.verifyOtp(emailCtrl.text.trim(), otpCtrl.text.trim());
      if (valid) { step.value = 2; return null; }
      return 'Código incorrecto';
    } catch (_) {
      return 'Error al verificar código';
    } finally {
      loading.value = false;
    }
  }

  Future<String?> updatePassword() async {
    if (!isPasswordValid(passCtrl.text)) return 'La contraseña no cumple los requisitos';
    loading.value = true;
    try {
      await _repo.resetPassword(emailCtrl.text.trim(), passCtrl.text.trim());
      return null;
    } catch (_) {
      return 'Error al actualizar la contraseña';
    } finally {
      loading.value = false;
    }
  }
}

// ─── RegisterViewModel ────────────────────────────────────────────────────────
class RegisterViewModel {
  final OtpService  _otp  = OtpService();
  final ApiClient   _http = ApiClient();

  final documentoCtrl         = TextEditingController();
  final emailVerificationCtrl = TextEditingController();
  final passCtrl              = TextEditingController();
  final confirmPassCtrl       = TextEditingController();
  final verificationCodeCtrl  = TextEditingController();

  final registrationStep = ValueNotifier<int>(0);
  final loading          = ValueNotifier<bool>(false);
  final foundUser        = ValueNotifier<Map<String, dynamic>?>(null);

  static const _institutionalApiUrl = 'https://ulv-api.apps.isdapps.uk/api/datos/';

  void dispose() {
    documentoCtrl.dispose();
    emailVerificationCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    verificationCodeCtrl.dispose();
    registrationStep.dispose();
    loading.dispose();
    foundUser.dispose();
  }

  bool isPasswordValid(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p) &&
      RegExp(r'[!"#\$%&/\(\)=\?\.,@]').hasMatch(p);

  Future<String?> searchByDocument() async {
    final doc = documentoCtrl.text.trim();
    if (doc.isEmpty) return 'Ingresa tu matrícula o número de empleado.';

    loading.value = true;
    try {
      final response = await http.get(Uri.parse('$_institutionalApiUrl$doc'));
      if (response.statusCode == 404) return 'No se encontró ningún usuario con ese documento.';
      if (response.statusCode >= 400) return 'Error al conectar con el servidor.';

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['Data'] ?? body['data']) as Map<String, dynamic>?;
      if (data == null) return 'Respuesta de API inválida.';

      final userType = (data['type'] ?? '').toString().toUpperCase();
      Map<String, dynamic>? userData;

      if (userType == 'ALUMNO' && data['student'] is List && (data['student'] as List).isNotEmpty) {
        userData = (data['student'] as List).first as Map<String, dynamic>;
      } else if (userType == 'EMPLEADO' && data['employee'] is List && (data['employee'] as List).isNotEmpty) {
        userData = (data['employee'] as List).first as Map<String, dynamic>;
      }

      if (userData == null) return 'No se encontraron datos válidos.';
      foundUser.value = userData;
      registrationStep.value = 1;
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  Future<String?> verifyEmailAndSendOtp() async {
    final typed   = emailVerificationCtrl.text.trim().toLowerCase();
    final real    = (foundUser.value?['EMAIl_INSTITUCIONAL'] ?? foundUser.value?['CORREO_INSTITUCIONAL'] ?? '').toString().toLowerCase();
    if (typed != real) return 'El correo electrónico no coincide.';

    loading.value = true;
    try {
      await _otp.sendOtp(real);
      registrationStep.value = 2;
      return null;
    } catch (_) {
      return 'Error al enviar correo.';
    } finally {
      loading.value = false;
    }
  }

  Future<String?> verifyCode() async {
    final code  = verificationCodeCtrl.text.trim();
    final email = (foundUser.value?['EMAIl_INSTITUCIONAL'] ?? foundUser.value?['CORREO_INSTITUCIONAL'] ?? '').toString();
    if (code.length != 4) return 'Ingresa el código completo.';

    loading.value = true;
    try {
      final valid = await _otp.verifyOtp(email, code);
      if (valid) { registrationStep.value = 3; return null; }
      return 'El código es incorrecto o ha expirado.';
    } catch (_) {
      return 'Error al validar.';
    } finally {
      loading.value = false;
    }
  }

  Future<String?> register() async {
    final user = foundUser.value;
    if (user == null) return 'Error: Se perdieron los datos del usuario.';
    if (passCtrl.text != confirmPassCtrl.text) return 'Las contraseñas no coinciden.';
    if (!isPasswordValid(passCtrl.text)) return 'La contraseña no cumple los requisitos.';

    loading.value = true;
    try {
      final esEmpleado = user.containsKey('NOMBRES');
      int idRol;
      if (esEmpleado) {
        idRol = (user['SEXO'] ?? '') == 'F' ? 3 : 2;
      } else {
        idRol = 4;
      }

      String residencia = 'Externa';
      String? direccion = user['DIRECCION']?.toString();
      final resRaw = (user['RESIDENCIA'] ?? '').toString().toUpperCase();
      if (resRaw.startsWith('INTERNO')) {
        residencia = 'Interna';
        direccion  = null;
      }
      if (residencia == 'Externa' && (direccion == null || direccion.isEmpty)) {
        direccion = 'Dirección no proporcionada por la institución';
      }

      final payload = {
        'nombre':            user['NOMBRES'] ?? user['NOMBRE'],
        'apellido':          user['APELLIDOS'],
        'correo':            user['EMAIl_INSTITUCIONAL'] ?? user['CORREO_INSTITUCIONAL'],
        'contrasena':        passCtrl.text,
        'tipo_usuario':      esEmpleado ? 'EMPLEADO' : 'ALUMNO',
        'id_rol':            idRol,
        'matricula':         esEmpleado ? null : _parseInt(user['MATRICULA']),
        'num_empleado':      esEmpleado ? _parseInt(user['MATRICULA']) : null,
        'residencia':        residencia,
        'direccion':         direccion,
        'telefono':          user['CELULAR'],
        'fecha_nacimiento':  user['FECHA_NACIMIENTO'],
        'carrera':           user['LeNombreEscuelaOficial'] ?? user['DEPARTAMENTO'],
      };

      final res = await _http.postJson(ApiEndpoints.usuarios, data: payload);
      if (res.statusCode >= 400) {
        final body = jsonDecode(res.body);
        String msg = body['error'] ?? body['message'] ?? 'Error ${res.statusCode}';
        if (msg.contains('UNIQUE KEY')) msg = 'El usuario ya está registrado.';
        return msg;
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
