import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Exponemos el stream authStateChanges
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Función para registrar un nuevo usuario
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Usuario registrado exitosamente.");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase en signUp: ${e.code}');
      print('Descripción: ${e.message}');
      String errorMessage = _handleAuthException(e);
      throw Exception('Error de registro: $errorMessage');
    } catch (e) {
      print('Error desconocido en signUp: $e');
      throw Exception('Error desconocido al registrar el usuario');
    }
  }

  // Función para iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Error de autenticación en signIn: ${e.code}");
      print("Mensaje: ${e.message}");
      String errorMessage = _handleAuthException(e);
      throw Exception('Error de inicio de sesión: $errorMessage');
    } catch (e) {
      print("Error desconocido en signIn: $e");
      throw Exception('Error desconocido al iniciar sesión');
    }
  }

  // Función para obtener el usuario actual
  User? getCurrentUser() {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return user;
      } else {
        print('No hay usuario actualmente autenticado.');
        return null;
      }
    } catch (e) {
      print('Error al obtener el usuario actual: $e');
      return null;
    }
  }

  // Función para cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Método auxiliar para manejar excepciones de FirebaseAuth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo electrónico ya está en uso.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'operation-not-allowed':
        return 'La operación no está permitida en la configuración actual.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      default:
        return e.message ?? 'Error desconocido';
    }
  }

  
}
