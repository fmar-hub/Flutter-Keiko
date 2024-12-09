import 'package:flutter/material.dart';

class AddNoteDialog extends StatelessWidget {
  final TextEditingController notesController;
  final void Function() onCancel;
  final void Function() onSave;

  const AddNoteDialog({
    super.key,
    required this.notesController,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Agregar nota"),
      content: TextField(
        controller: notesController,
        decoration: const InputDecoration(hintText: "Escribe una nota..."),
        maxLines: 3, // Permite varias líneas para la nota
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: onSave,
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
