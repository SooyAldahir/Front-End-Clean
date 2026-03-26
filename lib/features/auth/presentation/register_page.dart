import 'package:flutter/material.dart';
import 'auth_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final RegisterViewModel _vm = RegisterViewModel();
  final _otpCtrls = List.generate(4, (_) => TextEditingController());
  bool _obscurePass = true, _obscureConfirm = true;

  bool get _min8      => _vm.passCtrl.text.length >= 8;
  bool get _hasUpper  => RegExp(r'[A-Z]').hasMatch(_vm.passCtrl.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_vm.passCtrl.text);
  bool get _hasSpec   => RegExp(r'[!"#\$%&/\(\)=\?\.,@]').hasMatch(_vm.passCtrl.text);
  bool get _match     => _vm.passCtrl.text.isNotEmpty && _vm.passCtrl.text == _vm.confirmPassCtrl.text;
  bool get _allOk     => _min8 && _hasUpper && _hasNumber && _hasSpec && _match;

  @override
  void initState() {
    super.initState();
    _vm.passCtrl.addListener(() { if (mounted) setState(() {}); });
    _vm.confirmPassCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _vm.dispose(); for (final c in _otpCtrls) c.dispose(); super.dispose(); }

  void _snack(String msg, {bool error = true}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green, duration: const Duration(seconds: 3)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Crear Cuenta'), backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login)),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ValueListenableBuilder<int>(
              valueListenable: _vm.registrationStep,
              builder: (_, step, __) {
                switch (step) {
                  case 1: return _step1();
                  case 2: return _step2();
                  case 3: return _step3();
                  default: return _step0();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 0: Documento ───────────────────────────────────────────────────────
  Widget _step0() => Column(children: [
    const Image(image: AssetImage('assets/img/logo_edi.png'), width: 225, height: 225),
    const SizedBox(height: 20),
    const Text('Ingresa tu Matrícula o Número de Colaborador', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    _textField(controller: _vm.documentoCtrl, hint: 'Matrícula / No. Colaborador', icon: Icons.badge_outlined, keyboard: TextInputType.number),
    _actionBtn('Buscar', () async {
      final err = await _vm.searchByDocument();
      if (err != null && mounted) _snack(err);
    }),
  ]);

  // ─── Step 1: Verificar email ─────────────────────────────────────────────────
  Widget _step1() => ValueListenableBuilder<Map<String, dynamic>?>(
    valueListenable: _vm.foundUser,
    builder: (_, user, __) {
      if (user == null) { _vm.registrationStep.value = 0; return const SizedBox(); }
      final nombre   = '${user['NOMBRES'] ?? user['NOMBRE'] ?? ''} ${user['APELLIDOS'] ?? ''}'.trim();
      final correoOculto = _ocultarCorreo(user['EMAIl_INSTITUCIONAL'] ?? user['CORREO_INSTITUCIONAL'] ?? '');
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: Image(image: AssetImage('assets/img/logo_edi.png'), width: 225, height: 225)),
        const SizedBox(height: 20),
        const Text('¿Eres tú?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _dataRow('Nombre:', nombre),
        _dataRow('Correo:', correoOculto),
        const SizedBox(height: 20),
        const Text('Para verificar tu identidad, escribe tu correo institucional completo:', style: TextStyle(color: Colors.white70)),
        _textField(controller: _vm.emailVerificationCtrl, hint: 'Correo completo', icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
        _actionBtn('Verificar Correo y Enviar Código', () async {
          final err = await _vm.verifyEmailAndSendOtp();
          if (err != null && mounted) _snack(err);
        }),
      ]);
    },
  );

  // ─── Step 2: OTP ─────────────────────────────────────────────────────────────
  Widget _step2() => Column(children: [
    const Image(image: AssetImage('assets/img/logo_edi.png'), width: 150, height: 150),
    const SizedBox(height: 20),
    const Text('Ingresa el código de 4 dígitos que recibiste.', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
    const SizedBox(height: 30),
    _otpRow(),
    const SizedBox(height: 20),
    _actionBtn('Validar Código', () async {
      final err = await _vm.verifyCode();
      if (err != null && mounted) _snack(err);
    }),
  ]);

  // ─── Step 3: Password ────────────────────────────────────────────────────────
  Widget _step3() => Column(children: [
    const Image(image: AssetImage('assets/img/logo_edi.png'), width: 150, height: 150),
    const SizedBox(height: 20),
    const Text('¡Verificación exitosa!\nAhora crea tu contraseña:', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
    const SizedBox(height: 10),
    _textField(controller: _vm.passCtrl, hint: 'Contraseña', icon: Icons.key_outlined, obscure: _obscurePass,
      suffix: IconButton(icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: Colors.white70), onPressed: () => setState(() => _obscurePass = !_obscurePass))),
    _textField(controller: _vm.confirmPassCtrl, hint: 'Confirmar contraseña', icon: Icons.key_outlined, obscure: _obscureConfirm,
      suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: Colors.white70), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
    const SizedBox(height: 12),
    _RequirementCard(items: [
      _ReqItem(ok: _min8,     text: 'Mínimo 8 caracteres'),
      _ReqItem(ok: _hasUpper, text: 'Al menos 1 mayúscula (A-Z)'),
      _ReqItem(ok: _hasNumber,text: 'Al menos 1 número (0-9)'),
      _ReqItem(ok: _hasSpec,  text: r'Al menos 1 especial: !"#$%&/()=?.,@'),
      _ReqItem(ok: _match,    text: 'Las contraseñas coinciden'),
    ]),
    const SizedBox(height: 18),
    ValueListenableBuilder<bool>(
      valueListenable: _vm.loading,
      builder: (_, loading, __) {
        final disabled = loading || !_allOk;
        return SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : () async {
              final err = await _vm.register();
              if (!mounted) return;
              if (err != null) { _snack(err); return; }
              _snack('Registro exitoso. Ahora puedes iniciar sesión.', error: false);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, disabledBackgroundColor: AppColors.accent.withOpacity(0.45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 15)),
            child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                : Text('Completar Registro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: disabled ? Colors.black54 : Colors.black)),
          ),
        );
      },
    ),
  ]);

  Widget _textField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, TextInputType keyboard = TextInputType.text, Widget? suffix}) =>
    Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.accent, width: 2))),
      child: TextField(controller: controller, obscureText: obscure, keyboardType: keyboard, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.all(15), prefixIcon: Icon(icon, color: Colors.white), suffixIcon: suffix)),
    );

  Widget _actionBtn(String text, VoidCallback onPressed) => Container(
    width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 20),
    child: ValueListenableBuilder<bool>(
      valueListenable: _vm.loading,
      builder: (_, loading, __) => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 15)),
        child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
            : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
      ),
    ),
  );

  Widget _dataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(text: TextSpan(style: const TextStyle(color: Colors.white70, fontSize: 16), children: [
      TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      TextSpan(text: value),
    ])),
  );

  Widget _otpRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(4, (i) => SizedBox(width: 60, height: 60,
      child: TextField(
        controller: _otpCtrls[i], autofocus: i == 0, keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 1,
        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        decoration: InputDecoration(counterText: '', filled: true, fillColor: Colors.transparent, contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 2))),
        onChanged: (v) {
          if (v.length == 1 && i < 3) FocusScope.of(context).nextFocus();
          else if (v.isEmpty && i > 0) FocusScope.of(context).previousFocus();
          _vm.verificationCodeCtrl.text = _otpCtrls.map((c) => c.text).join();
          if (_vm.verificationCodeCtrl.text.length == 4) { FocusScope.of(context).unfocus(); _vm.verifyCode().then((e) { if (e != null && mounted) _snack(e); }); }
        },
      ),
    )),
  );

  String _ocultarCorreo(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final user  = parts[0];
    if (user.length <= 3) return '${user[0]}***@${parts[1]}';
    return '${user.substring(0, 3)}***@${parts[1]}';
  }
}

class _ReqItem { final bool ok; final String text; const _ReqItem({required this.ok, required this.text}); }

class _RequirementCard extends StatelessWidget {
  final List<_ReqItem> items;
  const _RequirementCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.map((it) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(it.ok ? Icons.check_circle : Icons.cancel, size: 18, color: it.ok ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(it.text, style: TextStyle(color: it.ok ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    )).toList()),
  );
}
