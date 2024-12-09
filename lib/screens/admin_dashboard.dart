import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('Cargando AdminDashboard'); // Agregar esto para depuración

    // Obtener el usuario actual de Firebase
    User? user = FirebaseAuth.instance.currentUser;

    // Si el usuario no está autenticado, redirigir al login
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }

    // Acceso a Firestore para obtener el nickname
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('usuarios').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error al cargar datos"));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("Usuario no encontrado"));
        }

        // Obtener el nickname desde Firestore
        String nickname = snapshot.data!['nickname'] ?? 'Administrador';

        return Scaffold(
          appBar: AppBar(
            title: Text("Panel de Administración"),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(nickname), // Mostrar el nickname real
                  accountEmail: Text(user?.email ?? 'admin@miapp.com'),  // Correo real del usuario
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                ),
                ListTile(
                  title: Text('Gestión de Usuarios'),
                  onTap: () {
                    Navigator.pushNamed(context, '/user_management');
                  },
                ),
                ListTile(
                  title: Text('Gestión de Roles'),
                  onTap: () {
                    Navigator.pushNamed(context, '/role_management');
                  },
                ),
                ListTile(
                  title: Text('Logs del Sistema'),
                  onTap: () {
                    Navigator.pushNamed(context, '/system_logs');
                  },
                ),
                ListTile(
                  title: Text('Ver Hábitos'),
                  onTap: () {
                    Navigator.pushNamed(context, '/habitspage');
                  },
                ),
                ListTile(
                  title: Text('Notificaciones'),
                  onTap: () {
                    Navigator.pushNamed(context, '/notificationspage');
                  },
                ),
                ListTile(
                  title: Text('Cerrar sesión'),
                  onTap: () async {
                    // Cerrar sesión de Firebase
                    await FirebaseAuth.instance.signOut();
                    // Redirigir al login
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
          body: Center(
            child: Text("Bienvenido al panel de administración"),
          ),
        );
      },
    );
  }
}
