import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String contactoUid;
  final String contactoNombre;

  const ChatScreen({
    super.key,
    required this.contactoUid,
    required this.contactoNombre,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatService _chatService = ChatService();
  final String _miUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final String _chatId;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _chatId = _chatService.generarChatId(_miUid, widget.contactoUid);
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final String texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;

    _mensajeCtrl.clear();
    setState(() => _enviando = true);

    try {
      await _chatService.enviarMensaje(
        receptorUid: widget.contactoUid,
        texto: texto,
      );
    } catch (_) {
      if (mounted) {
        _mensajeCtrl
          ..text = texto
          ..selection = TextSelection.collapsed(offset: texto.length);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el mensaje.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _marcarMensajesComoVistos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final ids = docs
        .where((doc) {
          final data = doc.data();
          return data['emisorUid'] != _miUid && data['estado'] != 'visto';
        })
        .map((doc) => doc.id)
        .toList();
    if (ids.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService
          .actualizarEstadoMensajes(
            chatId: _chatId,
            mensajeIds: ids,
            estado: 'visto',
          )
          .catchError((_) {});
    });
  }

  Widget _indicadorEstado(String estado, Color color) {
    if (estado == 'visto' || estado == 'recibido') {
      return Icon(
        Icons.done_all,
        size: 16,
        color: estado == 'visto' ? color : color.withValues(alpha: 0.7),
      );
    }
    return Icon(Icons.done, size: 16, color: color.withValues(alpha: 0.7));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color colorPrimario = theme.colorScheme.primary;
    final Color colorBurbujaPropia = isDark
        ? AppTheme.darkBubbleOwn
        : AppTheme.lightBubbleOwn;
    final Color colorBurbujaAjena = isDark
        ? AppTheme.darkBubbleOther
        : AppTheme.lightBubbleOther;
    final Color colorTextoPropio = isDark
        ? Colors.white
        : const Color(0xFF0F172A);
    final Color colorTextoAjeno = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : Colors.white24,
              child: Text(
                widget.contactoNombre.isNotEmpty
                    ? widget.contactoNombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.contactoNombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Área de mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.obtenerMensajes(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudieron cargar los mensajes.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                _marcarMensajesComoVistos(docs);

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: colorPrimario.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay mensajes aún.\n¡Saluda a ${widget.contactoNombre}!',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final String texto = data['texto'] ?? '';
                    final String emisorUid = data['emisorUid'] ?? '';
                    final Object? enviadoEnValor = data['enviadoEn'];
                    final Timestamp? enviadoEn = enviadoEnValor is Timestamp
                        ? enviadoEnValor
                        : null;
                    final bool esMio = emisorUid == _miUid;
                    final String estado =
                        data['estado'] as String? ?? 'enviado';

                    final String horaFormateada = enviadoEn != null
                        ? DateFormat('HH:mm').format(enviadoEn.toDate())
                        : '';

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 8.0,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: esMio ? colorBurbujaPropia : colorBurbujaAjena,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14.0),
                            topRight: const Radius.circular(14.0),
                            bottomLeft: Radius.circular(esMio ? 14.0 : 0.0),
                            bottomRight: Radius.circular(esMio ? 0.0 : 14.0),
                          ),
                          border: isDark && !esMio
                              ? Border.all(color: const Color(0xFF334155))
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                texto,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: esMio
                                      ? colorTextoPropio
                                      : colorTextoAjeno,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  horaFormateada,
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color:
                                        (esMio
                                                ? colorTextoPropio
                                                : colorTextoAjeno)
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                                if (esMio) ...[
                                  const SizedBox(width: 3),
                                  _indicadorEstado(estado, colorTextoPropio),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Barra inferior para escribir
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(
                            color: colorPrimario,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  CircleAvatar(
                    backgroundColor: colorPrimario,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _enviar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
