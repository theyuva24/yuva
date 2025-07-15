import 'package:flutter/material.dart';
import '../models/hub_model.dart';
import '../service/hub_service.dart';
import 'hub_details_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF181C23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C23),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F6FF)),
        title: Text(
          'Hubs',
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F6FF),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 16,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Hub>>(
        stream: hubService.getHubsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F6FF)),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading hubs',
                style: TextStyle(color: Color(0xFF00F6FF)),
              ),
            );
          }
          final hubs = snapshot.data ?? [];
          if (hubs.isEmpty) {
            return const Center(
              child: Text(
                'No hubs available.',
                style: TextStyle(color: Color(0xFF00F6FF)),
              ),
            );
          }
          return ListView.builder(
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final hub = hubs[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF232733),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xFF00F6FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00F6FF).withOpacity(0.12),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF00F6FF), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00F6FF).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(hub.imageUrl),
                      backgroundColor: Color(0xFF181C23),
                    ),
                  ),
                  title: Text(
                    hub.name,
                    style: GoogleFonts.orbitron(
                      textStyle: const TextStyle(
                        color: Color(0xFF00F6FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(color: Color(0xFF00F6FF), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  subtitle: Text(
                    hub.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
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
        backgroundColor: const Color(0xFF00F6FF),
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Create Hub',
      ),
    );
  }
}
