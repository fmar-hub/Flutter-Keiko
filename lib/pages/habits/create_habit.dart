import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';
import 'package:flutter_keiko/services/IA/ia_improve.dart';

class CreateHabitPage extends StatefulWidget {
  const CreateHabitPage({super.key});

  @override
  _CreateHabitPageState createState() => _CreateHabitPageState();
}

class _CreateHabitPageState extends State<CreateHabitPage> {
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController =
      TextEditingController();
  final TextEditingController _emojiController = TextEditingController();
  String _selectedCategory = "Salud";
  Color _selectedColor = Colors.blue;
  bool _isChallenging = false;
  int _challengeDays = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime(2100, 12, 31);

  final OpenAIImproveService _improveService = OpenAIImproveService();
  bool _isProcessingAI = false;

  final List<String> _categories = [
    "Salud",
    "Estudio",
    "Ejercicio",
    "Bienestar",
    "Trabajo"
  ];

  Future<void> _selectColor() async {
    Color pickedColor = _selectedColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar Color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
              showLabel: false,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pickedColor),
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );

    setState(() {
      _selectedColor = pickedColor;
    });
  }

  void _improveHabitDetails() async {
    if (_habitNameController.text.isEmpty &&
        _habitDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor ingresa un nombre o descripción")),
      );
      return;
    }

    setState(() {
      _isProcessingAI = true; // Mostrar el indicador de carga
    });

    try {
      final improvedDetails = await _improveService.improveHabitDetails(
        name: _habitNameController.text,
        description: _habitDescriptionController.text,
      );

      setState(() {
        _habitNameController.text =
            improvedDetails['name'] ?? _habitNameController.text;
        _habitDescriptionController.text =
            improvedDetails['description'] ?? _habitDescriptionController.text;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Error al mejorar los detalles del hábito. Intenta de nuevo.")),
      );
    } finally {
      setState(() {
        _isProcessingAI = false; // Ocultar el indicador de carga
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: isStartDate ? _startDate : _endDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        ) ??
        DateTime.now();

    setState(() {
      if (isStartDate) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _saveHabit() async {
    if (_habitNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("El nombre del hábito no puede estar vacío")),
      );
      return;
    }

    if (_isChallenging && _challengeDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Debes seleccionar la cantidad de días para el reto")),
      );
      return;
    }

    if (_isChallenging) {
      _endDate = _startDate.add(Duration(days: _challengeDays));
    }

    final newHabit = Habit(
      id: 'some_unique_id', // Asegúrate de generar un ID único
      name: _habitNameController.text,
      description: _habitDescriptionController.text, // Se pasa description aquí
      emoji: _emojiController.text.isEmpty ? "😊" : _emojiController.text,
      color: _selectedColor.value,
      isChallenging: _isChallenging,
      challengeDays: _challengeDays,
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
    );

    final firebaseHabitService = FirebaseHabitService();
    await firebaseHabitService.saveHabit(newHabit);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hábito creado con éxito")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEDE7DD),
      title: const Text("Crear Hábito"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width *
            0.8, // 80% del ancho de la pantalla
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _habitNameController,
                decoration:
                    const InputDecoration(labelText: "Nombre del Hábito"),
              ),
              TextField(
                controller: _habitDescriptionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              const SizedBox(height: 16),
              if (_isProcessingAI)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _improveHabitDetails,
                  icon: const Icon(Icons.lightbulb),
                  label: const Text("Mejorar con IA"),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _selectedColor,
                    radius: 30,
                    child: Text(
                      _emojiController.text.isEmpty
                          ? "😊"
                          : _emojiController.text,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _emojiController,
                          decoration: const InputDecoration(
                            labelText: "Seleccionar Emoji",
                            hintText: "Ejemplo: 😊",
                          ),
                          maxLength: 1,
                        ),
                        ElevatedButton(
                          onPressed: _selectColor,
                          child: const Text("Seleccionar Color"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newCategory) {
                  setState(() {
                    _selectedCategory = newCategory!;
                  });
                },
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fecha de inicio: ${DateFormat('dd-MM-yyyy').format(_startDate)}",
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isChallenging) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Fecha de fin: ${DateFormat('dd-MM-yyyy').format(_endDate)}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text("Seleccionar Fecha de Inicio"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("¿Este hábito es desafiante?"),
                  Row(
                    children: [
                      const Text("Sí"),
                      Checkbox(
                        value: _isChallenging,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChallenging = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isChallenging) ...[
                    const SizedBox(height: 8),
                    const Text("¿Cuánto tiempo quieres hacer este hábito?"),
                    DropdownButton<int>(
                      value: _challengeDays == 0 ? null : _challengeDays,
                      items: [7, 14, 21, 30].map((days) {
                        return DropdownMenuItem(
                            value: days, child: Text('$days días'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _challengeDays = value ?? 0;
                          if (_challengeDays > 0) {
                            _endDate =
                                _startDate.add(Duration(days: _challengeDays));
                          }
                        });
                      },
                      hint: const Text("Seleccionar días para el reto"),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          child: const Text("Guardar Hábito"),
        ),
      ],
    );
  }
}
