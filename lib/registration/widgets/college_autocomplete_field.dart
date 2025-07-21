import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    final String jsonString = await rootBundle.loadString(
      'assets/colleges.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    // Extract all unique values from the maps
    final Set<String> collegeSet = {};
    for (final item in jsonList) {
      if (item is Map) {
        collegeSet.addAll(item.keys.map((e) => e.toString()));
        collegeSet.addAll(item.values.map((e) => e.toString()));
      }
    }
    setState(() {
      _colleges = collegeSet.toList();
      _loading = false;
    });
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
          (option) => option.toLowerCase().contains(
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
                  content: Text('You can suggest "$newCollege" to the admin.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
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
