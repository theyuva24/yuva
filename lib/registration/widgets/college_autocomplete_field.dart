import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSelected;
  const CollegeAutocompleteField({
    Key? key,
    this.initialValue,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<CollegeAutocompleteField> createState() =>
      _CollegeAutocompleteFieldState();
}

class _CollegeAutocompleteFieldState extends State<CollegeAutocompleteField> {
  late TextEditingController _controller;
  List<String> _colleges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('colleges').get();
    setState(() {
      _colleges = snapshot.docs.map((doc) => doc['name'] as String).toList();
      _loading = false;
    });
  }

  Future<void> _suggestCollege(String name) async {
    await FirebaseFirestore.instance.collection('pending_colleges').add({
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('College suggestion sent for admin approval.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        final matches = _colleges.where(
          (option) => option.toLowerCase().startsWith(
            textEditingValue.text.toLowerCase(),
          ),
        );
        if (matches.isEmpty) {
          return ['Add "${textEditingValue.text}"'];
        }
        return matches;
      },
      onSelected: (String selection) {
        if (selection.startsWith('Add "')) {
          final newCollege = selection.substring(5, selection.length - 1);
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Add New College'),
                  content: Text(
                    'Do you want to suggest "$newCollege" as a new college?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _suggestCollege(newCollege);
                        Navigator.pop(context);
                      },
                      child: Text('Submit'),
                    ),
                  ],
                ),
          );
        } else {
          widget.onSelected(selection);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        _controller = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.school),
            hintText: 'College/Institution',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
          style: Theme.of(context).textTheme.bodyMedium,
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }
}
