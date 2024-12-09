import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoleManagement extends StatelessWidget {
  // Referencia a la colección de roles en Firestore
  final CollectionReference rolesRef = FirebaseFirestore.instance.collection('roles');

  // Función para editar un rol
  void _editRole(BuildContext context, DocumentSnapshot roleDoc) {
    TextEditingController roleNameController = TextEditingController(text: roleDoc['Nombre_Rol']);
    TextEditingController roleEmailController = TextEditingController(text: roleDoc['correo']);
    TextEditingController roleUsernameController = TextEditingController(text: roleDoc['nombre_usuario']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Rol"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleNameController,
                decoration: InputDecoration(labelText: "Nombre del Rol"),
              ),
              TextField(
                controller: roleEmailController,
                decoration: InputDecoration(labelText: "Correo Electrónico"),
              ),
              TextField(
                controller: roleUsernameController,
                decoration: InputDecoration(labelText: "Nombre de Usuario"),
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
                await rolesRef.doc(roleDoc.id).update({
                  'Nombre_Rol': roleNameController.text,
                  'correo': roleEmailController.text,
                  'nombre_usuario': roleUsernameController.text,
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

  // Función para eliminar un rol
  void _deleteRole(BuildContext context, DocumentSnapshot roleDoc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eliminar Rol"),
          content: Text("¿Estás seguro de que deseas eliminar el rol '${roleDoc['Nombre_Rol']}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                // Eliminar el documento de Firestore
                await rolesRef.doc(roleDoc.id).delete();
                Navigator.pop(context);
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  // Función para crear un nuevo rol
  void _createRole(BuildContext context) {
    TextEditingController roleNameController = TextEditingController();
    TextEditingController roleEmailController = TextEditingController();
    TextEditingController roleUsernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Crear Rol"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleNameController,
                decoration: InputDecoration(labelText: "Nombre del Rol"),
              ),
              TextField(
                controller: roleEmailController,
                decoration: InputDecoration(labelText: "Correo Electrónico"),
              ),
              TextField(
                controller: roleUsernameController,
                decoration: InputDecoration(labelText: "Nombre de Usuario"),
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
                // Validar campos obligatorios
                if (roleNameController.text.isEmpty ||
                    roleEmailController.text.isEmpty ||
                    roleUsernameController.text.isEmpty) {
                  // Mostrar un mensaje de error si algún campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Todos los campos son obligatorios'),
                  ));
                  return;
                }

                // Crear el nuevo rol en Firestore
                await rolesRef.add({
                  'Nombre_Rol': roleNameController.text,
                  'correo': roleEmailController.text,
                  'nombre_usuario': roleUsernameController.text,
                });
                Navigator.pop(context);
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
        title: Text("Gestión de Roles"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _createRole(context),
            child: Text("Crear Rol"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: rolesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar roles"));
                }

                final roles = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    var roleDoc = roles[index];
                    var role = roleDoc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(role['Nombre_Rol'] ?? 'Sin nombre del rol'),
                      subtitle: Text('${role['correo']} | ${role['nombre_usuario']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editRole(context, roleDoc);
                          } else if (value == 'delete') {
                            _deleteRole(context, roleDoc);
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
