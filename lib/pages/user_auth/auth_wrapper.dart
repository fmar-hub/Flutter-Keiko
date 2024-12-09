import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // Reemplaza con el path a tu página de login
import 'package:flutter_keiko/pages/home/home.dart'; // Reemplaza con el path a tu página de inicio

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ha ocurrido un error'));
        } else if (snapshot.hasData) {
          return Home(); // Redirigir a Home si está autenticado
        } else {
          return const Login(); // Redirigir a Login si no está autenticado
        }
      },
    );
  }
}
