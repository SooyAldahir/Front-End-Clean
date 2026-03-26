import 'package:flutter/material.dart';
import 'chat_viewmodel.dart';
import 'chat_page.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/utils/url_helper.dart';

class MyChatsPage extends StatefulWidget {
  const MyChatsPage({super.key});
  @override
  State<MyChatsPage> createState() => _MyChatsPageState();
}

class _MyChatsPageState extends State<MyChatsPage> {
  final MyChatsViewModel _vm = MyChatsViewModel();

  @override
  void initState() { super.initState(); _vm.load(); }
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    }
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Conversaciones'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _vm.loading,
          builder: (_, loading, __) {
            if (loading) return const Center(child: CircularProgressIndicator());
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: _vm.chats,
              builder: (_, chats, __) {
                if (chats.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('No tienes chats activos', style: TextStyle(color: Colors.grey[600])),
                ]));
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat    = chats[i] as Map<String, dynamic>;
                    final tipo    = chat['tipo']?.toString() ?? '';
                    final fotoUrl = toAbsoluteUrl(chat['foto_perfil_chat']?.toString());
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tipo == 'GRUPAL' ? Colors.orange : AppColors.primary,
                        backgroundImage: (tipo != 'GRUPAL' && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                        child: (tipo != 'GRUPAL' && fotoUrl.isNotEmpty) ? null : Icon(tipo == 'GRUPAL' ? Icons.groups : Icons.person, color: Colors.white),
                      ),
                      title: Text(chat['titulo_chat'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(chat['ultimo_mensaje'] ?? 'Inicia la conversación...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
                      trailing: Text(_formatDate(chat['fecha_ultimo']?.toString()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(idSala: chat['id_sala'] as int, nombreChat: chat['titulo_chat'] ?? 'Chat')));
                        _vm.load();
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.info, color: Colors.black),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ve a la sección de Familias o Alumnos para iniciar un chat.'))),
      ),
    );
  }
}
