import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerDialog({
    Key? key,
    required this.initialColor,
    required this.onColorSelected,
  }) : super(key: key);

  Future<void> _selectColor(BuildContext context) async {
    Color pickedColor = initialColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar Color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
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
    onColorSelected(pickedColor);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectColor(context),
      child: const Text("Seleccionar Color"),
    );
  }
}
