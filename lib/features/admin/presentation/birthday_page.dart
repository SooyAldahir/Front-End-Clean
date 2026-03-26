import 'package:flutter/material.dart';
import 'package:edi301/features/admin/data/admin_repository.dart';
import 'package:edi301/shared/models/user.dart';
import 'package:edi301/core/network/api_client.dart';

class BirthdaysPage extends StatefulWidget {
  const BirthdaysPage({super.key});

  @override
  State<BirthdaysPage> createState() => _BirthdaysPageState();
}

class _BirthdaysPageState extends State<BirthdaysPage> {
  final AdminRepository _api = AdminRepository();
  List<dynamic> _cumpleaneros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarCumpleaneros();
  }

  void _cargarCumpleaneros() async {
    final lista = await _api.getCumpleaneros();
    if (mounted) setState(() { _cumpleaneros = lista; _loading = false; });
  }

  void _irAlChat(Map<String, dynamic> usuario) {
    final id     = usuario['id_usuario'] ?? usuario['id'] ?? 0;
    final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
    Navigator.pushNamed(context, 'chat', arguments: {'id_usuario': id, 'nombre': nombre, 'foto_perfil': usuario['foto_perfil']});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cumpleaños de Hoy 🎂"),
        backgroundColor: const Color.fromRGBO(19, 67, 107, 1),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _cumpleaneros.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cumpleaneros.length,
                itemBuilder: (context, index) {
                  final user = _cumpleaneros[index] as Map<String, dynamic>;
                  return _buildBirthdayCard(user);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Hoy no hay cumpleaños registrados.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayCard(Map<String, dynamic> user) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.pinkAccent, width: 2),
      ),
      color: Colors.pink[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "🎉 ¡ES SU CUMPLEAÑOS! 🎉",
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: user['foto_perfil'] != null ? NetworkImage('${ApiClient.baseUrl}${user['foto_perfil']}') : null,
              child: user['foto_perfil'] == null ? Text((user['nombre'] ?? '?').toString()[0], style: const TextStyle(fontSize: 30)) : null,
            ),
            const SizedBox(height: 10),
            Text(
              '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _irAlChat(user as Map<String, dynamic>),
              icon: const Icon(Icons.chat_bubble),
              label: const Text("Enviar Felicitación"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
