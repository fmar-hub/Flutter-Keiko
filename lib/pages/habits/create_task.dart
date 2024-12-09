import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:flutter_keiko/models/task_model.dart';
import 'package:flutter_keiko/services/firebase_task_service.dart';
import 'package:flutter/cupertino.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFrequency;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedHabitId;
  final List<Map<String, String>> _habits = [];
  final List<String> _frequencies = ['Diario', 'Semanal', 'Mensual'];
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('habits').get();
      setState(() {
        _habits.clear();
        _habits.addAll(snapshot.docs.map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
            }).toList());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los hábitos')),
      );
    }
  }

  String? _validateDates() {
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      return 'La fecha de inicio no puede ser posterior a la fecha de término';
    }
    return null;
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_validateDates() != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_validateDates()!)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String taskId = const Uuid().v4();

      final Task newTask = Task(
        id: taskId,
        habitId: _selectedHabitId!,
        frequency: _selectedFrequency!, // Pass frequency
        name: '', // You can set a default or input for the name
        description: '', // You can add a description input if necessary
        completed: false,
        dueDate: _endDate ?? DateTime.now(), // If no end date, use current
      );

      final FirebaseTaskService taskService = FirebaseTaskService();
      await taskService.saveTask(newTask);  // Ensure saveTask supports the frequency field

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea creada exitosamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la tarea')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStartDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _startDate ?? DateTime.now(),
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _startDate = newDateTime;
                _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate!);
              });
            },
          ),
        );
      },
    );
  }

  void _showEndDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _endDate ?? DateTime.now(),
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _endDate = newDateTime;
                _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Tarea'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Hábito'),
                      value: _selectedHabitId,
                      hint: const Text('Selecciona un hábito'), // Esto cambiará "Hábito" por un texto más amigable
                      items: _habits.map((habit) {
                        return DropdownMenuItem<String>(
                          value: habit['id'],
                          child: Text(habit['name']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedHabitId = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona un hábito' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Frecuencia'),
                      value: _selectedFrequency,
                      hint: const Text('Selecciona una frecuencia'), // Esto cambiará "Frecuencia"
                      items: _frequencies.map((frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFrequency = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona una frecuencia' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Fecha de inicio'),
                      readOnly: true,
                      controller: _startDateController,
                      onTap: _showStartDatePicker,
                      validator: (value) => _startDate == null ? 'Selecciona una fecha de inicio' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Fecha de término (opcional)'),
                      readOnly: true,
                      controller: _endDateController,
                      onTap: _showEndDatePicker,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTask,
                      child: const Text('Guardar Tarea'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
