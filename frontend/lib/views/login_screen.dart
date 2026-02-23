import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/agro_api_service.dart';
import '../models/agro_usuario.dart';

// ── Paleta AgroConnect ────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF1B5E20); // verde oscuro
const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF66BB6A);
const _kBg = Colors.white;
const _kText = Color(0xFF1C1C1C);
const _kSubtext = Color(0xFF757575);

/// Pantalla de Login/Registro adaptada a la identidad visual de AgroConnect.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _authService = AuthService();
  final _apiService = AgroApiService();
  int _idRol = 2; // 2 = Comprador por defecto
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegistering = false;

  void _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegistering) {
        // 1. Crear usuario en Firebase
        await _authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 2. Registrar perfil en el backend (PostgREST / Supabase)
        await _apiService.crearUsuario(
          AgroUsuarioCreate(
            nombre: _nombreController.text.trim().isEmpty
                ? 'Usuario Nuevo'
                : _nombreController.text.trim(),
            email: _emailController.text.trim(),
            telefono: _telefonoController.text.trim(),
            ubicacion: _ubicacionController.text.trim(),
            idRol: _idRol,
          ),
        );
      } else {
        await _authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // El AuthWrapper en main.dart maneja la navegación automáticamente
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('] ')
            ? e.toString().split('] ')[1]
            : e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo / ícono ───────────────────────────────────────────
                Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 52,
                        color: _kGreen,
                      ),
                    )
                    .animate()
                    .scale(duration: 500.ms)
                    .then()
                    .shimmer(
                      duration: 800.ms,
                      color: _kGreenLight.withOpacity(0.3),
                    ),
                const SizedBox(height: 20),

                // ── Título principal ───────────────────────────────────────
                Text(
                  'AgroConnect',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.3),

                Text(
                  _isRegistering
                      ? 'Crea tu cuenta de productor'
                      : 'Mercado agrícola comunitario',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSubtext),
                  textAlign: TextAlign.center,
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 36),

                // ── Error ──────────────────────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(),

                // ── Campos extra de Registro ──────────────────────────────
                if (_isRegistering) ...[
                  _AgroTextField(
                    controller: _nombreController,
                    label: 'Nombre completo o Granja',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _AgroTextField(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _AgroTextField(
                          controller: _ubicacionController,
                          label: 'Ciudad/Zona',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Selector de Rol
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FDF8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _idRol,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kGreen,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Soy Productor / Vendedor'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Soy Comprador / Cliente'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _idRol = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Campo Email ────────────────────────────────────────────
                _AgroTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // ── Campo Contraseña ───────────────────────────────────────
                _AgroTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 28),

                // ── Botón principal (Email) ────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kGreenLight.withOpacity(0.4),
                      elevation: 4,
                      shadowColor: _kGreen.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isRegistering ? 'REGISTRARSE' : 'INICIAR SESIÓN',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),
                ),

                // ── Divider "O" + Google (solo en login) ──────────────────
                if (!_isRegistering) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'O',
                          style: GoogleFonts.outfit(
                            color: _kSubtext,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              try {
                                await _authService.signInWithGoogle();
                              } catch (e) {
                                setState(() => _errorMessage = 'Error: $e');
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 28,
                        color: _kGreen,
                      ),
                      label: Text(
                        'Continuar con Google',
                        style: GoogleFonts.outfit(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Toggle Registrar / Login ────────────────────────────────
                TextButton(
                  onPressed: () => setState(() {
                    _isRegistering = !_isRegistering;
                    _errorMessage = null;
                  }),
                  child: Text(
                    _isRegistering
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate',
                    style: GoogleFonts.outfit(
                      color: _kGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto con estilo AgroConnect (fondo blanco, borde gris suave).
class _AgroTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AgroTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      // Texto legible sobre fondo blanco
      style: GoogleFonts.outfit(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: _kSubtext, fontSize: 14),
        prefixIcon: Icon(icon, color: _kGreen, size: 22),
        filled: true,
        fillColor: const Color(0xFFF8FDF8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kGreen, width: 1.8),
        ),
      ),
    );
  }
}
