import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> actualizarPresencia({
    required bool online,
    bool escribiendo = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('usuarios').doc(uid).set({
      'online': online,
      'escribiendo': escribiendo,
      'ultimaConexion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> actualizarEscribiendo(bool escribiendo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('usuarios').doc(uid).set({
      'escribiendo': escribiendo,
    }, SetOptions(merge: true));
  }

  // Obtener usuario actual
  User? get usuarioActual => _auth.currentUser;

  // Registro con nombre, correo y contraseña
  Future<UserCredential> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: correo.trim(),
            password: clave.trim(),
          );

      final String uid = userCredential.user!.uid;

      // Guardar perfil público en la colección 'usuarios'
      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'contactos': <String>[],
      });

      // Actualizar el displayName en FirebaseAuth
      await userCredential.user?.updateDisplayName(nombre.trim());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _traducirErrorAuth(e.code);
    } catch (e) {
      throw 'Ocurrió un error inesperado al registrarse.';
    }
  }

  // Inicio de sesión con correo y contraseña
  Future<UserCredential> iniciarSesion({
    required String correo,
    required String clave,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: clave.trim(),
      );
      final usuario = credential.user!;
      await _firestore.collection('usuarios').doc(usuario.uid).set({
        'uid': usuario.uid,
        'correo': (usuario.email ?? correo).trim().toLowerCase(),
        'nombre':
            usuario.displayName ?? usuario.email?.split('@').first ?? 'Usuario',
        'contactos': FieldValue.arrayUnion(<String>[]),
      }, SetOptions(merge: true));
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _traducirErrorAuth(e.code);
    } catch (e) {
      throw 'Ocurrió un error inesperado al iniciar sesión.';
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // Restablecer contraseña / Enviar correo de recuperación
  Future<void> recuperarClave(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on FirebaseAuthException catch (e) {
      throw _traducirErrorAuth(e.code);
    } catch (e) {
      throw 'Ocurrió un error al enviar el correo de recuperación.';
    }
  }

  // Traducción de códigos de error de FirebaseAuth al español
  String _traducirErrorAuth(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido inhabilitada.';
      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo electrónico.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo y contraseña no está habilitado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Inténtalo de nuevo más tarde.';
      default:
        return 'Error de autenticación ($codigo). Por favor intenta de nuevo.';
    }
  }
}
