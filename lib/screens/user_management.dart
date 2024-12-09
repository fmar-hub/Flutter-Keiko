import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagement extends StatelessWidget {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('usuarios');

  final List<String> _genderOptions = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decirlo'
  ];
  String? _selectedGender;
  DateTime? _birthDate;

  void _editUser(BuildContext context, DocumentSnapshot userDoc) {
    // Mostrar un diálogo para editar al usuario
    TextEditingController nicknameController =
        TextEditingController(text: userDoc['nickname']);
    TextEditingController emailController =
        TextEditingController(text: userDoc['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Usuario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(labelText: "Apodo"),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Correo Electrónico"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                // Actualizar el documento en Firestore
                await _usersRef.doc(userDoc.id).update({
                  'nickname': nicknameController.text,
                  'email': emailController.text,
                });
                Navigator.pop(context);
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(BuildContext context, DocumentSnapshot userDoc) {
    // Confirmación antes de eliminar
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eliminar Usuario"),
          content: Text(
              "¿Estás seguro de que deseas eliminar a '${userDoc['nickname']}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                // Eliminar el documento de Firestore
                await _usersRef.doc(userDoc.id).delete();
                Navigator.pop(context);
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void _createUser(BuildContext context) async {
    TextEditingController nicknameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Crear Usuario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(labelText: "Apodo"),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Correo Electrónico"),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Contraseña"),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: "Confirmar Contraseña"),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  onChanged: (value) {
                    _selectedGender = value;
                  },
                  items: _genderOptions
                      .map((gender) => DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  decoration: InputDecoration(labelText: 'Género'),
                ),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null && pickedDate != _birthDate) {
                      _birthDate = pickedDate;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: _birthDate == null
                            ? 'Fecha de nacimiento'
                            : _birthDate.toString(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                if (nicknameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty ||
                    _selectedGender == null ||
                    _birthDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Por favor, complete todos los campos.")));
                } else if (passwordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Las contraseñas no coinciden")));
                } else {
                  try {
                    // Crear el usuario en Firebase Auth
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text);

                    // Obtener el UID del usuario recién creado
                    String userId = userCredential.user!.uid;

                    // Convertir la fecha de nacimiento en timestamp
                    Timestamp birthDateTimestamp = _birthDate != null
                        ? Timestamp.fromDate(_birthDate!)
                        : Timestamp.now();

                    // Crear el documento de usuario en Firestore
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(userId)
                        .set({
                      'nickname': nicknameController.text,
                      'email': emailController.text,
                      'gender': _selectedGender,
                      'birth_date': birthDateTimestamp,
                      'date_register': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Usuario creado exitosamente")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Error al crear el usuario: $e")));
                  }
                }
              },
              child: Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestión de Usuarios"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _createUser(context),
            child: Text("Crear Usuario"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar usuarios"));
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userDoc = users[index];
                    var user = userDoc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(user['nickname'] ?? 'Sin apodo'),
                      subtitle: Text(user['email'] ?? 'Sin correo electrónico'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editUser(context, userDoc);
                          } else if (value == 'delete') {
                            _deleteUser(context, userDoc);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
