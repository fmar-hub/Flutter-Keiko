import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String labelText;

  const DatePickerField({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.labelText,
  }) : super(key: key);

  @override
  _DatePickerFieldState createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ) ?? widget.selectedDate;

    if (picked != widget.selectedDate) {
      setState(() {
        widget.onDateSelected(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${widget.labelText}: ${DateFormat('dd-MM-yyyy').format(widget.selectedDate)}",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _selectDate(context),
          child: Text("Seleccionar ${widget.labelText}"),
        ),
      ],
    );
  }
}
