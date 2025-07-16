import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeAdminPage extends StatefulWidget {
  @override
  State<CollegeAdminPage> createState() => _CollegeAdminPageState();
}

class _CollegeAdminPageState extends State<CollegeAdminPage> {
  final TextEditingController _addController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Colleges')),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
                  child: Text('Add'),
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
                  return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return Center(child: Text('No pending colleges.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final name = doc['name'];
                    return ListTile(
                      title: Text(name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('colleges')
                                  .add({'name': name});
                              await doc.reference.delete();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final controller = TextEditingController(
                                text: name,
                              );
                              final newName = await showDialog<String>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Edit College Name'),
                                      content: TextField(
                                        controller: controller,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, null),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                                controller.text,
                                              ),
                                          child: Text('Save'),
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
                            icon: Icon(Icons.close, color: Colors.red),
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
    );
  }
}
