import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Importa este paquete para usar ImageFilter


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _genderOptions = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decirlo'];
  String? _selectedGender;
  DateTime? _birthDate;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isAgeValid(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;

    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
      age--;
    }

    return age >= 10;
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null || !_isAgeValid(_birthDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes tener al menos 10 años para registrarte')));
        return;
      }

      try {
        User? user = await _auth.signUp(_emailController.text, _passwordController.text);

        if (user != null) {
          String userId = user.uid;
          Timestamp birthDateTimestamp = _birthDate != null ? Timestamp.fromDate(_birthDate!) : Timestamp.now();

          await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
            'email': _emailController.text,
            'nickname': _nicknameController.text,
            'date_register': FieldValue.serverTimestamp(),
            'gender': _selectedGender,
            'date_birth': birthDateTimestamp,
          });

          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario registrado exitosamente')));
        }
      } catch (e) {
        print('Error en registro: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar usuario')));
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _birthDate) {
      setState(() {
        _birthDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/image/fondo-login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                constraints: const BoxConstraints(maxWidth: 350),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/image/icon.png", width: 200, height: 150),
                      const SizedBox(height: 20),
                      const Text('¡Feliz de conocerte!', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(labelText: 'Nickname', fillColor: Colors.white, filled: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu nickname';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Correo electrónico', fillColor: Colors.white, filled: true),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Contraseña', fillColor: Colors.white, filled: true),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Confirmar contraseña', fillColor: Colors.white, filled: true),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        items: _genderOptions
                            .map((gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Género', fillColor: Colors.white, filled: true),
                      ),
                      const SizedBox(height: 16.0),
                      GestureDetector(
                        onTap: () => _selectBirthDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: _birthDate == null ? 'Fecha de nacimiento' : _birthDate.toString(),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _signUp,
                        child: const Text('Registrarse'),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta?', style: TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text('Inicia sesión', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
