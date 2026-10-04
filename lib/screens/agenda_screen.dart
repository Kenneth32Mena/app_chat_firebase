import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final String miUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorPrimario = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bubble_chart_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'Contactos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
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
                await authService.cerrarSesion();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los contactos.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final contactos = docs.where((doc) => doc.id != miUid).toList();

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
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
      ),
    );
  }
}
