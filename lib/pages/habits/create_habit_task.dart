import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateHabitAndTasksPage extends StatefulWidget {
  const CreateHabitAndTasksPage({super.key});

  @override
  _CreateHabitAndTasksPageState createState() =>
      _CreateHabitAndTasksPageState();
}

class _CreateHabitAndTasksPageState extends State<CreateHabitAndTasksPage> {
  final _habitFormKey = GlobalKey<FormState>();
  final _taskFormKey = GlobalKey<FormState>();

  final _habitNameController = TextEditingController();
  final _taskNameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String? _selectedFrequency;
  DateTime? _habitStartDate;
  DateTime? _habitEndDate;

  bool _isLoading = false;
  String? _habitId;
  final List<Map<String, dynamic>> _tasks = [];

  final List<String> _frequencies = ['Diario', 'Semanal', 'Mensual'];

  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _taskNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Hábito y Tareas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Form(
                    key: _habitFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear Hábito',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _habitNameController,
                          decoration: const InputDecoration(
                              labelText: 'Nombre del Hábito'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Introduce un nombre'
                              : null,
                          enabled: _habitId == null, // Desactiva al guardar
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: 'Frecuencia'),
                          value: _selectedFrequency,
                          items: _frequencies.map((frequency) {
                            return DropdownMenuItem<String>(
                              value: frequency,
                              child: Text(frequency),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (_habitId == null) {
                              setState(() {
                                _selectedFrequency = newValue;
                              });
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Selecciona una frecuencia' : null,
                        ),
                        TextFormField(
                          controller: _startDateController,
                          decoration: const InputDecoration(
                              labelText: 'Fecha de inicio'),
                          readOnly: true,
                          onTap: _habitId == null
                              ? () async {
                                  final DateTime? picked =
                                      await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _habitStartDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _habitStartDate = picked;
                                      _startDateController.text =
                                          DateFormat('yyyy-MM-dd')
                                              .format(picked);
                                    });
                                  }
                                }
                              : null,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Selecciona una fecha de inicio'
                              : null,
                        ),
                        TextFormField(
                          controller: _endDateController,
                          decoration: const InputDecoration(
                              labelText: 'Fecha de término (opcional)'),
                          readOnly: true,
                          onTap: _habitId == null
                              ? () async {
                                  final DateTime? picked =
                                      await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _habitEndDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _habitEndDate = picked;
                                      _endDateController.text =
                                          DateFormat('yyyy-MM-dd')
                                              .format(picked);
                                    });
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _habitId == null ? _saveHabit : null,
                          child: const Text('Guardar Hábito'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  if (_habitId != null) ...[
                    Form(
                      key: _taskFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Añadir Tareas para este Hábito',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _taskNameController,
                            decoration: const InputDecoration(
                                labelText: 'Nombre de la Tarea'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Introduce un nombre'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _addTask,
                            child: const Text('Añadir Tarea'),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Tareas asociadas:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ..._tasks.map((task) => ListTile(
                                title: Text(task['name']),
                                subtitle:
                                    Text('ID del Hábito: ${task['habitId']}'),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _saveHabit() async {
    if (!_habitFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final habitData = {
        'userId': _userId,
        'name': _habitNameController.text.trim(),
        'frequency': _selectedFrequency,
        'startDate': _habitStartDate?.toIso8601String(),
        'endDate': _habitEndDate?.toIso8601String(),
      };

      final docRef =
          await FirebaseFirestore.instance.collection('user_habits').add(habitData);
      setState(() {
        _habitId = docRef.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hábito creado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el hábito: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    if (!_taskFormKey.currentState!.validate()) return;

    final taskData = {
      'habitId': _habitId,
      'userId': _userId,
      'name': _taskNameController.text.trim(),
      'status': 'Pendiente',
    };

    try {
      await FirebaseFirestore.instance
          .collection('user_habits')
          .doc(_habitId)
          .collection('tasks')
          .add(taskData);

      setState(() {
        _tasks.add(taskData);
      });

      _taskNameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la tarea: $e')),
      );
    }
  }
}
