import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitsPage extends StatelessWidget {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('usuarios');
  final CollectionReference _userHabitsRef =
      FirebaseFirestore.instance.collection('users_habits');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hábitos de Usuarios'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar usuarios: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay usuarios registrados.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;

              return ExpansionTile(
                title: Text(user['nickname'] ?? 'Sin apodo'),
                subtitle: Text(user['email'] ?? 'Sin correo'),
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: _userHabitsRef.doc(userId).collection('habits').get(),
                    builder: (context, habitsSnapshot) {
                      if (habitsSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (habitsSnapshot.hasError) {
                        return ListTile(
                          title: Text('Error al cargar hábitos: ${habitsSnapshot.error}'),
                        );
                      }

                      if (!habitsSnapshot.hasData || habitsSnapshot.data!.docs.isEmpty) {
                        return ListTile(
                          title: Text('No hay hábitos registrados.'),
                        );
                      }

                      final habits = habitsSnapshot.data!.docs;

                      return Column(
                        children: habits.map((habitDoc) {
                          var habit = habitDoc.data() as Map<String, dynamic>;

                          return ListTile(
                            leading: Text(habit['emoji'] ?? '🙂'),
                            title: Text(habit['name'] ?? 'Sin nombre'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Descripción: ${habit['description'] ?? ''}'),
                                Text('Categoría: ${habit['category'] ?? ''}'),
                                Text('Días de reto: ${habit['challengeDays'] ?? ''}'),
                              ],
                            ),
                            trailing: Icon(
                              Icons.circle,
                              color: Color(habit['color'] ?? 0xFF000000),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
