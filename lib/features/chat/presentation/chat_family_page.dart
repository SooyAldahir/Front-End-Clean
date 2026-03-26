import 'package:flutter/material.dart';
import 'chat_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class ChatFamilyPage extends StatefulWidget {
  final int idFamilia;
  final String nombreFamilia;
  const ChatFamilyPage({super.key, required this.idFamilia, required this.nombreFamilia});
  @override
  State<ChatFamilyPage> createState() => _ChatFamilyPageState();
}

class _ChatFamilyPageState extends State<ChatFamilyPage> {
  final ChatFamilyViewModel _vm = ChatFamilyViewModel();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm.init(widget.idFamilia);
    _vm.messages.addListener(_scrollToBottom);
  }

  @override
  void dispose() { _vm.messages.removeListener(_scrollToBottom); _vm.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Color _colorForName(String name) {
    final colors = [Colors.red[700]!, Colors.pink[700]!, Colors.purple[700]!, Colors.indigo[700]!, Colors.blue[700]!, Colors.teal[700]!, Colors.green[700]!, Colors.orange[800]!, Colors.brown[700]!];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombreFamilia), backgroundColor: AppColors.primary, elevation: 0),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(child: ValueListenableBuilder<bool>(
            valueListenable: _vm.loading,
            builder: (_, loading, __) {
              if (loading) return const Center(child: CircularProgressIndicator());
              return ValueListenableBuilder<List<dynamic>>(
                valueListenable: _vm.messages,
                builder: (_, msgs, __) => ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg   = msgs[i] as Map<String, dynamic>;
                    final esMio = msg['id_usuario'] == _vm.miId;
                    return _bubble(msg, esMio);
                  },
                ),
              );
            },
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 5)]),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _vm.msgCtrl, minLines: 1, maxLines: 4,
                decoration: InputDecoration(hintText: 'Escribe un mensaje...', contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100]),
              )),
              const SizedBox(width: 8),
              CircleAvatar(backgroundColor: AppColors.primary, radius: 24, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () async {
                final ok = await _vm.sendMessage(widget.idFamilia);
                if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar mensaje')));
              })),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> msg, bool esMio) {
    final hora     = msg['created_at']?.toString().length != null && msg['created_at'].toString().length >= 16 ? msg['created_at'].toString().substring(11, 16) : '';
    final nombre   = (msg['nombre'] ?? 'Desconocido').toString();
    final fotoUrl  = msg['foto_perfil'] != null ? '${ApiClient.baseUrl}${msg['foto_perfil']}' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esMio) ...[
            CircleAvatar(radius: 14, backgroundColor: Colors.grey[300], backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
              child: fotoUrl == null ? Text(nombre.isNotEmpty ? nombre[0] : '?', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)) : null),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: esMio ? AppColors.primary : AppColors.accent,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: esMio ? const Radius.circular(18) : const Radius.circular(2), bottomRight: esMio ? const Radius.circular(2) : const Radius.circular(18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(1, 1))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!esMio) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(nombre, style: TextStyle(fontSize: 12, color: _colorForName(nombre), fontWeight: FontWeight.bold))),
                Text(msg['mensaje'] ?? '', style: TextStyle(fontSize: 15, color: esMio ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Align(alignment: Alignment.bottomRight, child: Text(hora, style: TextStyle(fontSize: 10, color: esMio ? Colors.white70 : Colors.grey[600]))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
