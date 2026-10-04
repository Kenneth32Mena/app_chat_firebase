import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _claveCtrl = TextEditingController();

  bool _esModoRegistro = false;
  bool _cargando = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      if (_esModoRegistro) {
        await _authService.registrar(
          nombre: _nombreCtrl.text,
          correo: _correoCtrl.text,
          clave: _claveCtrl.text,
        );
      } else {
        await _authService.iniciarSesion(
          correo: _correoCtrl.text,
          clave: _claveCtrl.text,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _mostrarDialogoRecuperarClave() async {
    final TextEditingController correoRecuperarCtrl =
        TextEditingController(text: _correoCtrl.text);
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final colorPrimario = theme.colorScheme.primary;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: colorPrimario),
                  const SizedBox(width: 8),
                  const Text(
                    'Restablecer Clave',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: correoRecuperarCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (!resetFormKey.currentState!.validate()) return;

                          setDialogState(() => enviando = true);
                          try {
                            await _authService
                                .recuperarClave(correoRecuperarCtrl.text);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Se ha enviado un correo de recuperación a ${correoRecuperarCtrl.text.trim()}.',
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (error) {
                            setDialogState(() => enviando = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Enviar enlace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorPrimario = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón para alternar modo oscuro / claro
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: colorPrimario,
            ),
            tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono Ártico
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: colorPrimario.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.ac_unit_rounded,
                          size: 52.0,
                          color: colorPrimario,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Título
                      Text(
                        _esModoRegistro ? 'Crear Cuenta' : 'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _esModoRegistro
                            ? 'Completa tus datos para registrarte'
                            : 'Ingresa tus credenciales para continuar',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),

                      // Campo Nombre (solo en registro)
                      if (_esModoRegistro) ...[
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (_esModoRegistro && (value == null || value.trim().isEmpty)) {
                              return 'Por favor ingresa tu nombre completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // Campo Correo
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu correo electrónico';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo Contraseña
                      TextFormField(
                        controller: _claveCtrl,
                        obscureText: _ocultarClave,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarClave ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _ocultarClave = !_ocultarClave);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      // Botón ¿Olvidaste tu contraseña? (solo en modo login)
                      if (!_esModoRegistro) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _cargando ? null : _mostrarDialogoRecuperarClave,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: colorPrimario,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.0,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24.0),
                      ],

                      // Botón Principal / Indicador de Carga
                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _procesarFormulario,
                          child: _cargando
                              ? const SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _esModoRegistro ? 'Registrarse' : 'Ingresar',
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Alternar modo
                      TextButton(
                        onPressed: _cargando
                            ? null
                            : () {
                                setState(() {
                                  _esModoRegistro = !_esModoRegistro;
                                  _formKey.currentState?.reset();
                                });
                              },
                        child: RichText(
                          text: TextSpan(
                            text: _esModoRegistro
                                ? '¿Ya tienes una cuenta? '
                                : '¿No tienes una cuenta? ',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                            children: [
                              TextSpan(
                                text: _esModoRegistro ? 'Inicia Sesión' : 'Regístrate aquí',
                                style: TextStyle(
                                  color: colorPrimario,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
