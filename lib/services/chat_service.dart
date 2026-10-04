import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  // Genera un ID determinista y único para el chat entre dos usuarios
  String generarChatId(String uidA, String uidB) {
    final List<String> ids = [uidA, uidB]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  // Envía un mensaje y actualiza la información del chat padre
  Future<void> enviarMensaje({
    required String receptorUid,
    required String texto,
  }) async {
    final User? usuarioActual = _auth.currentUser;
    if (usuarioActual == null || texto.trim().isEmpty) return;

    final String emisorUid = usuarioActual.uid;
    final Timestamp ahora = Timestamp.now();
    final String chatId = generarChatId(emisorUid, receptorUid);

    // 1. Actualizar/Crear primero el documento padre del chat con merge: true
    // (Garantiza que exista para las reglas de seguridad de la subcolección)
    await _firestore.collection('chats').doc(chatId).set({
      'participantes': [emisorUid, receptorUid],
      'ultimoMensaje': texto.trim(),
      'ultimaActualizacion': ahora,
    }, SetOptions(merge: true));

    // 2. Guardar el nuevo mensaje en la subcolección
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .add({
          'texto': texto.trim(),
          'emisorUid': emisorUid,
          'enviadoEn': ahora,
          'estado': 'enviado',
        });
  }

  Future<void> actualizarEstadoMensajes({
    required String chatId,
    required Iterable<String> mensajeIds,
    required String estado,
  }) async {
    final batch = _firestore.batch();
    for (final mensajeId in mensajeIds) {
      batch.update(
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('mensajes')
            .doc(mensajeId),
        {'estado': estado},
      );
    }
    await batch.commit();
  }

  // Obtiene el Stream de mensajes ordenados cronológicamente
  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerMensajes(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('enviadoEn', descending: false)
        // También notifica las escrituras locales mientras Firebase confirma
        // el envío, para que el chat se actualice sin esperar otra consulta.
        .snapshots(includeMetadataChanges: true);
  }
}
