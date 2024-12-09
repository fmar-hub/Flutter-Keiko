import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_keiko/models/task_model.dart';

class FirebaseTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Guardar una tarea
  Future<void> saveTask(Task task) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users_tasks')
          .doc(userId)
          .collection('tasks')
          .add(task.toMap());
    }
  }

  // Obtener todas las tareas
  Future<List<Task>> getTasks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('users_tasks')
        .doc(userId)
        .collection('tasks')
        .get();

    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obtener una tarea específica por ID
  Future<Task?> getTaskById(String taskId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || taskId.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users_tasks')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .get();

    if (snapshot.exists) {
      return Task.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Editar una tarea existente
  Future<void> updateTask(String taskId, Task task) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users_tasks')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update(task.toMap());
    }
  }

  // Eliminar una tarea
  Future<void> deleteTask(String taskId) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users_tasks')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    }
  }
}
