import 'package:flutter_test/flutter_test.dart';
import 'package:app_chat_firebase/services/chat_service.dart';

void main() {
  final chatService = ChatService();

  group('ChatService', () {
    test('genera el mismo ID sin importar el orden de los usuarios', () {
      final idOriginal = chatService.generarChatId('usuario-a', 'usuario-b');
      final idInvertido = chatService.generarChatId('usuario-b', 'usuario-a');

      expect(idOriginal, 'usuario-a_usuario-b');
      expect(idInvertido, idOriginal);
    });

    test('mantiene separados los chats de pares de usuarios distintos', () {
      final primerChat = chatService.generarChatId('usuario-a', 'usuario-b');
      final segundoChat = chatService.generarChatId('usuario-a', 'usuario-c');

      expect(primerChat, isNot(equals(segundoChat)));
    });
  });
}
