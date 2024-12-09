import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keiko/services/firebase_auth_service.dart';
import 'package:flutter_keiko/pages/home/home.dart';
import 'package:flutter_keiko/screens/admin_dashboard.dart';
import 'sign_up.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false; // Variable para controlar el estado de carga

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      _showLoading(true);

      try {
        final User? user = await _authService.signInWithEmailAndPassword(email, password);
        _showLoading(false);

        if (user != null) {
          if (email.endsWith('@keiko.com')) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          }
        }
      } catch (e) {
        _showLoading(false);
        _showError(e);
      }
    }
  }

  void _showLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _showError(dynamic error) {
    String errorMessage = 'Ha ocurrido un error';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'No se encontró un usuario con este correo.';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido.';
          break;
        default:
          errorMessage = 'Error desconocido: ${error.message}';
      }
    } else {
      errorMessage = 'Error: $error';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image/fondo-login.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Efecto de desenfoque
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          // Contenedor de la UI principal
          Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono de imagen en la parte superior
                Image.asset(
                  "assets/image/icon.png",
                  width: 200,
                  height: 150,
                ),
                const SizedBox(height: 20),
                const Text(
                  "¡Bienvenid@!",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20.0),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Campo para el correo electrónico
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Correo electrónico',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo para la contraseña
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'Contraseña',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32.0),

                      // Botón de inicio de sesión
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                      const SizedBox(height: 10.0),

                      // Enlace para redirigir a la pantalla de registro
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUp()),
                          );
                        },
                        child: Text(
                          '¿No tienes una cuenta? Regístrate',
                          style: TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(2.0, 2.0),
                                blurRadius: 5.0,
                                color: Colors.red[200] ?? Colors.black,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        fillColor: Colors.white,
        filled: true,
        errorStyle: const TextStyle(color: Colors.white),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
