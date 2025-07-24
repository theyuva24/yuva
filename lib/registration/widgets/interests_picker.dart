import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../universal/theme/app_theme.dart';

class InterestsPicker extends StatefulWidget {
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;
  final int maxSelection;
  const InterestsPicker({
    Key? key,
    this.initialSelected = const [],
    required this.onChanged,
    this.maxSelection = 5,
  }) : super(key: key);

  @override
  State<InterestsPicker> createState() => _InterestsPickerState();
}

class _InterestsPickerState extends State<InterestsPicker> {
  late TextEditingController _searchController;
  List<String> _allInterests = [];
  List<String> _filteredInterests = [];
  List<String> _selected = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = List.from(widget.initialSelected);
    _loadInterests();
    _searchController.addListener(_filterInterests);
  }

  Future<void> _loadInterests() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/interests.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final Set<String> interestSet = {};
      for (final item in jsonList) {
        if (item is Map) {
          interestSet.addAll(item.values.map((e) => e.toString()));
        }
      }
      _allInterests = interestSet.toList();
      _allInterests.sort();
      _filterInterests();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      print('Error loading interests.json: $e\n$st');
      setState(() {
        _loading = false;
        _error = 'Failed to load interests. Please contact support.';
      });
    }
  }

  void _filterInterests() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInterests =
            _allInterests
                .where((i) => !_selected.contains(i))
                .take(10)
                .toList();
      } else {
        _filteredInterests =
            _allInterests
                .where(
                  (i) =>
                      i.toLowerCase().contains(query) && !_selected.contains(i),
                )
                .take(10)
                .toList();
      }
    });
  }

  void _addInterest(String interest) {
    if (_selected.length >= widget.maxSelection || _selected.contains(interest))
      return;
    setState(() {
      _selected.add(interest);
      widget.onChanged(_selected);
      _searchController.clear(); // Clear the search field after selection
      _filterInterests();
    });
  }

  void _removeInterest(String interest) {
    setState(() {
      _selected.remove(interest);
      widget.onChanged(_selected);
      _filterInterests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    final query = _searchController.text.trim();
    final canAddCustom =
        query.isNotEmpty &&
        !_allInterests
            .map((e) => e.toLowerCase())
            .contains(query.toLowerCase()) &&
        !_selected.map((e) => e.toLowerCase()).contains(query.toLowerCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search interests',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppThemeLight.divider),
            ),
            labelStyle: TextStyle(color: AppThemeLight.primary),
            filled: true,
            fillColor: AppThemeLight.surface,
            hintStyle: TextStyle(color: AppThemeLight.textSecondary),
          ),
          style: TextStyle(color: AppThemeLight.textPrimary),
        ),
        const SizedBox(height: 12),
        if (_selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selected
                    .map(
                      (interest) => Chip(
                        label: Text(interest),
                        backgroundColor: AppThemeLight.primary,
                        labelStyle: TextStyle(color: AppThemeLight.surface),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeInterest(interest),
                      ),
                    )
                    .toList(),
          ),
        if (_selected.isNotEmpty) const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._filteredInterests.map(
              (interest) => FilterChip(
                label: Text(
                  interest,
                  style: TextStyle(color: AppThemeLight.textPrimary),
                ),
                selected: false,
                backgroundColor: AppThemeLight.surface,
                side: BorderSide(color: AppThemeLight.divider, width: 2),
                checkmarkColor: AppThemeLight.primary,
                onSelected: (_) => _addInterest(interest),
              ),
            ),
            if (canAddCustom)
              FilterChip(
                label: Text(
                  'Add "$query"',
                  style: TextStyle(color: AppThemeLight.primary),
                ),
                selected: false,
                backgroundColor: AppThemeLight.surface,
                side: BorderSide(color: AppThemeLight.primary, width: 2),
                onSelected: (_) => _addInterest(query),
              ),
          ],
        ),
      ],
    );
  }
}
