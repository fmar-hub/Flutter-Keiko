import 'package:flutter/material.dart';
import 'package:flutter_keiko/services/firebase_auth_service.dart';
import 'package:flutter_keiko/pages/user_auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Instancia de FirebaseAuthService
    final FirebaseAuthService authService = FirebaseAuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,  // Usamos el stream de authStateChanges expuesto
      builder: (context, snapshot) {
        // Muestra un indicador de carga mientras se determina el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si no hay un usuario autenticado, redirige al login
        if (snapshot.hasError || snapshot.data == null) {
          return const Login();
        }

        // Si está autenticado, muestra la página protegida
        return child;
      },
    );
  }
}
