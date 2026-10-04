import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final AuthService _authService = AuthService();
  final String _miUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _agregarContacto() async {
    final correoCtrl = TextEditingController();
    final correo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar contacto'),
        content: TextField(
          controller: correoCtrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'contacto@correo.com',
          ),
          onSubmitted: (_) => Navigator.pop(context, correoCtrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, correoCtrl.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    correoCtrl.dispose();
    if (correo == null || correo.trim().isEmpty || !mounted) return;

    try {
      final resultado = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('correo', isEqualTo: correo.trim())
          .limit(1)
          .get();

      if (!mounted) return;
      if (resultado.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No existe un usuario con ese correo.')),
        );
        return;
      }

      final contactoUid = resultado.docs.first.id;
      if (contactoUid == _miUid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes agregarte a ti mismo.')),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance.collection('usuarios').doc(_miUid),
        {
          'contactos': FieldValue.arrayUnion([contactoUid]),
        },
        SetOptions(merge: true),
      );
      batch.set(
        FirebaseFirestore.instance.collection('usuarios').doc(contactoUid),
        {
          'contactos': FieldValue.arrayUnion([_miUid]),
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacto agregado correctamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar el contacto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorPrimario = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bubble_chart_rounded, size: 22),
            SizedBox(width: 8),
            Text('Contactos', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Agregar contacto por correo',
            onPressed: _agregarContacto,
          ),
          // Botón para alternar modo oscuro / claro
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            tooltip: isDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          // Botón cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que deseas salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await _authService.cerrarSesion();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_miUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los contactos.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final datosUsuario = snapshot.data?.data() ?? {};
          final idsContactos =
              (datosUsuario['contactos'] as List<dynamic>? ?? [])
                  .whereType<String>()
                  .toSet();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .snapshots(),
            builder: (context, usuariosSnapshot) {
              if (usuariosSnapshot.hasError) {
                return const Center(
                  child: Text('Error al cargar los contactos.'),
                );
              }
              if (usuariosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final contactos = (usuariosSnapshot.data?.docs ?? [])
                  .where((doc) => idsContactos.contains(doc.id))
                  .toList();

              if (contactos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 64,
                          color: colorPrimario.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay otros usuarios registrados todavía.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: contactos.length,
                separatorBuilder: (context, index) => Divider(
                  indent: 72.0,
                  height: 1.0,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                itemBuilder: (context, index) {
                  final data = contactos[index].data();
                  final String contactoUid = data['uid'] ?? contactos[index].id;
                  final String nombre = data['nombre'] ?? 'Usuario';
                  final String correo = data['correo'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: colorPrimario,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            contactoUid: contactoUid,
                            contactoNombre: nombre,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
