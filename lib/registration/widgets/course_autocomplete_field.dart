import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CourseAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSelected;
  final String? educationLevel; // 'Under Graduation' or 'Post Graduation'
  const CourseAutocompleteField({
    Key? key,
    this.initialValue,
    required this.onSelected,
    this.educationLevel,
  }) : super(key: key);

  @override
  State<CourseAutocompleteField> createState() =>
      _CourseAutocompleteFieldState();
}

class _CourseAutocompleteFieldState extends State<CourseAutocompleteField> {
  late TextEditingController _controller;
  List<String> _courses = [];
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.educationLevel != null) {
      _fetchCourses();
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant CourseAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.educationLevel != oldWidget.educationLevel) {
      if (widget.educationLevel != null) {
        setState(() {
          _loading = true;
          _errorText = null;
        });
        _fetchCourses();
      } else {
        setState(() {
          _courses = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchCourses() async {
    String file = 'assets/ug_courses.json';
    if (widget.educationLevel == 'Post Graduation') {
      file = 'assets/pg_courses.json';
    }
    final String jsonString = await rootBundle.loadString(file);
    final List<dynamic> jsonList = json.decode(jsonString);
    // Extract all unique values from the maps
    final Set<String> courseSet = {};
    for (final item in jsonList) {
      if (item is Map) {
        courseSet.addAll(item.values.map((e) => e.toString()));
      }
    }
    setState(() {
      _courses = courseSet.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (widget.educationLevel == null) {
              if (textEditingValue.text.isNotEmpty) {
                setState(() {
                  _errorText = 'Please select education level first';
                });
              }
              return const Iterable<String>.empty();
            }
            _errorText = null;
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
          fieldViewBuilder: (
            context,
            controller,
            focusNode,
            onEditingComplete,
          ) {
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
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4.0),
            child: Text(
              _errorText!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
