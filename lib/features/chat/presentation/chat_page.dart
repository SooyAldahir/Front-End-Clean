import 'package:flutter/material.dart';
import 'chat_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';

class ChatPage extends StatefulWidget {
  final int idSala;
  final String nombreChat;
  const ChatPage({super.key, required this.idSala, required this.nombreChat});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatViewModel _vm = ChatViewModel();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm.init(widget.idSala);
    _vm.messages.addListener(_scrollToBottom);
  }

  @override
  void dispose() { _vm.messages.removeListener(_scrollToBottom); _vm.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombreChat), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: ValueListenableBuilder<bool>(
            valueListenable: _vm.loading,
            builder: (_, loading, __) {
              if (loading) return const Center(child: CircularProgressIndicator());
              return ValueListenableBuilder<List<dynamic>>(
                valueListenable: _vm.messages,
                builder: (_, msgs, __) {
                  if (msgs.isEmpty) return const Center(child: Text('Inicia la conversación...'));
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(10),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg   = msgs[i] as Map<String, dynamic>;
                      final esMio = msg['es_mio'] == 1 || msg['es_mio'] == true;
                      return Align(
                        alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: esMio ? AppColors.accent : Colors.grey[300],
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: esMio ? const Radius.circular(15) : Radius.zero, bottomRight: esMio ? Radius.zero : const Radius.circular(15)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (!esMio) Text((msg['nombre_remitente'] ?? 'Usuario').toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                            Text((msg['mensaje'] ?? '').toString(), style: const TextStyle(fontSize: 16)),
                            if (msg['_temp'] == true) const Text('Enviando...', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          ]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _vm.msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _vm.sendMessage(widget.idSala),
                decoration: InputDecoration(hintText: 'Escribe un mensaje...', contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)), filled: true, fillColor: Colors.grey[100]),
              )),
              const SizedBox(width: 10),
              CircleAvatar(backgroundColor: AppColors.primary, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _vm.sendMessage(widget.idSala))),
            ]),
          ),
        ]),
      ),
    );
  }
}
