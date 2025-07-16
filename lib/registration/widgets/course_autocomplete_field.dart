import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CourseAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSelected;
  const CourseAutocompleteField({
    Key? key,
    this.initialValue,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<CourseAutocompleteField> createState() =>
      _CourseAutocompleteFieldState();
}

class _CourseAutocompleteFieldState extends State<CourseAutocompleteField> {
  late TextEditingController _controller;
  List<String> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final String jsonString = await rootBundle.loadString(
      'assets/courses.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      _courses = jsonList.cast<String>();
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
        final matches = _courses.where(
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
          final newCourse = selection.substring(5, selection.length - 1);
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Add New Course'),
                  content: Text(
                    'You can suggest "$newCourse" as a new course to the admin.',
                  ),
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
            prefixIcon: const Icon(Icons.collections_bookmark),
            hintText: 'Course',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
          style: Theme.of(context).textTheme.bodyMedium,
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }
}
