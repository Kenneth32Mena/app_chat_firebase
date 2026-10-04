# app_chat_firebase

Aplicación de mensajería en Flutter con Firebase Authentication y Cloud Firestore.

## Ejecutar dos chats al mismo tiempo

Abre dos terminales en la carpeta del proyecto y ejecuta:

```powershell
# Terminal 1
flutter run -d chrome --web-port 5000

# Terminal 2
flutter run -d chrome --web-port 5001
```

Cada puerto abre una sesión independiente de la aplicación. Inicia sesión
con dos usuarios distintos y abre el mismo contacto en ambas ventanas para
comprobar que los mensajes y sus horas aparecen en tiempo real.

## Tests

Ejecuta los tests sin depender de Firebase ni de una conexión de red:

```powershell
flutter test
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
