import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';

class CollegeAdminPage extends StatefulWidget {
  @override
  State<CollegeAdminPage> createState() => _CollegeAdminPageState();
}

class _CollegeAdminPageState extends State<CollegeAdminPage> {
  final TextEditingController _addController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data:
          Theme.of(context).brightness == Brightness.dark
              ? AppThemeDark.theme
              : AppThemeLight.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Colleges'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
          ),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      decoration: InputDecoration(
                        labelText: 'Add New College',
                        border: const OutlineInputBorder(),
                        labelStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _addController.text.trim();
                      if (name.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('colleges')
                            .add({'name': name});
                        _addController.clear();
                        setState(() {});
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('pending_colleges')
                        .orderBy('timestamp')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Center(child: Text('No pending colleges.'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final name = doc['name'];
                      return ListTile(
                        title: Text(
                          name,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppThemeDark.textPrimary
                                    : AppThemeLight.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppThemeDark.success
                                        : AppThemeLight.success,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('colleges')
                                    .add({'name': name});
                                await doc.reference.delete();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppThemeDark.info
                                        : AppThemeLight.info,
                              ),
                              onPressed: () async {
                                final controller = TextEditingController(
                                  text: name,
                                );
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Edit College Name'),
                                        content: TextField(
                                          controller: controller,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  null,
                                                ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  controller.text,
                                                ),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                );
                                if (newName != null &&
                                    newName.trim().isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('colleges')
                                      .add({'name': newName.trim()});
                                  await doc.reference.delete();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppThemeDark.errorText
                                        : AppThemeLight.errorText,
                              ),
                              onPressed: () async {
                                await doc.reference.delete();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
