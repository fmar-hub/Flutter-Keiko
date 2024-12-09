import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  _DailyTasksPageState createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _tasksByHabit;
  Map<String, List<Map<String, dynamic>>> _cachedTasksByHabit = {};

  @override
  void initState() {
    super.initState();
    _tasksByHabit = _fetchDailyTasks();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchDailyTasks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return {};
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    Map<String, List<Map<String, dynamic>>> groupedTasks = {};

    for (var doc in querySnapshot.docs) {
      final habitData = doc.data();
      final habitName = habitData['name'] ?? 'Hábito sin nombre';
      final tasks = List<Map<String, dynamic>>.from(habitData['tasks'] ?? []);

      // Filtrar tareas del día
      final today = DateTime.now();
      final todayTasks = tasks.where((task) {
        // Aquí puedes agregar lógica para comprobar la frecuencia.
        // Este ejemplo solo muestra todas las tareas.
        return true;
      }).toList();

      if (todayTasks.isNotEmpty) {
        groupedTasks[habitName] = todayTasks;
      }
    }

    _cachedTasksByHabit = groupedTasks;
    return groupedTasks;
  }

  void _updateTaskCompletion(String habitName, Map<String, dynamic> task, bool? value) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      task['completed'] = value;
    });

    // Actualizar en Firebase
    final habitDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('habits')
        .where('name', isEqualTo: habitName)
        .limit(1)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final habitId = snapshot.docs.first.id;
            final habitRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('habits')
                .doc(habitId);

            habitRef.update({
              'tasks': FieldValue.arrayUnion([task]),
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tareas del Día"),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _tasksByHabit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar las tareas"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay tareas para hoy"));
          }

          final tasksByHabit = _cachedTasksByHabit.isNotEmpty ? _cachedTasksByHabit : snapshot.data!;

          return ListView.builder(
            itemCount: tasksByHabit.length,
            itemBuilder: (context, index) {
              final habitName = tasksByHabit.keys.elementAt(index);
              final tasks = tasksByHabit[habitName]!;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(habitName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: tasks.map((task) {
                    return ListTile(
                      title: Text(task['name']),
                      subtitle: Text(task['description']),
                      trailing: Checkbox(
                        value: task['completed'] ?? false,
                        onChanged: (value) {
                          _updateTaskCompletion(habitName, task, value);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
