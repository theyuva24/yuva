import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDatePicked;
  const DatePickerField({
    super.key,
    required this.initialDate,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100, now.month, now.day);
    final maxDate = DateTime(now.year - 13, now.month, now.day);
    return GestureDetector(
      onTap: () async {
        // Unfocus before opening the picker
        FocusScope.of(context).requestFocus(FocusNode());
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate ?? maxDate,
          firstDate: minDate,
          lastDate: maxDate,
        );
        // Unfocus again after closing the picker
        FocusScope.of(context).requestFocus(FocusNode());
        if (picked != null) {
          onDatePicked(picked);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            border: const OutlineInputBorder(),
          ),
          controller: TextEditingController(
            text:
                initialDate != null
                    ? DateFormat('dd MMM yyyy').format(initialDate!)
                    : '',
          ),
          readOnly: true,
        ),
      ),
    );
  }
}
