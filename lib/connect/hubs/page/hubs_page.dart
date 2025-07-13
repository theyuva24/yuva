import 'package:flutter/material.dart';
import '../model/hub_model.dart';
import '../service/hub_service.dart';
import 'hub_details_page.dart';

class HubsPage extends StatelessWidget {
  const HubsPage({super.key});

  void _showCreateHubDialog(BuildContext context, HubService hubService) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _createHub() async {
              if (nameController.text.trim().isEmpty) return;
              setState(() => isLoading = true);
              const String placeholderImage =
                  'https://ui-avatars.com/api/?name=Hub&background=6C63FF&color=fff&rounded=true&size=128';
              try {
                await hubService.createHub(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  imageUrl: placeholderImage,
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create hub: $e')),
                );
              } finally {
                setState(() => isLoading = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Create Hub',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Hub Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _createHub,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HubService hubService = HubService();
    return Scaffold(
      appBar: AppBar(title: const Text('Hubs')),
      body: StreamBuilder<List<Hub>>(
        stream: hubService.getHubsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading hubs'));
          }
          final hubs = snapshot.data ?? [];
          if (hubs.isEmpty) {
            return const Center(child: Text('No hubs available.'));
          }
          return ListView.builder(
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final hub = hubs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(hub.imageUrl),
                  ),
                  title: Text(hub.name),
                  subtitle: Text(hub.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HubDetailsPage(hub: hub),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateHubDialog(context, hubService),
        child: const Icon(Icons.add),
        tooltip: 'Create Hub',
      ),
    );
  }
}
