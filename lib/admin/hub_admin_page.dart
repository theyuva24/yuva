import 'package:flutter/material.dart';
import '../connect/hubs/service/hub_service.dart';
import '../connect/hubs/model/hub_model.dart';
import '../connect/hubs/page/hub_details_page.dart';
import '../registration/widgets/profile_image_picker.dart';

class HubAdminPage extends StatefulWidget {
  const HubAdminPage({super.key});

  @override
  State<HubAdminPage> createState() => _HubAdminPageState();
}

class _HubAdminPageState extends State<HubAdminPage> {
  final HubService hubService = HubService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? imagePath;
  Hub? editingHub;
  bool isLoading = false;

  void _resetForm() {
    nameController.clear();
    descriptionController.clear();
    imagePath = null;
    editingHub = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (nameController.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      String imageUrl =
          editingHub?.imageUrl ??
          'https://ui-avatars.com/api/?name=Hub&background=6C63FF&color=fff&rounded=true&size=128';
      String hubId =
          editingHub?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      if (imagePath != null) {
        final uploadedUrl = await hubService.uploadHubImage(imagePath, hubId);
        if (uploadedUrl != null) imageUrl = uploadedUrl;
      }
      if (editingHub == null) {
        await hubService.createHub(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
        );
      } else {
        await hubService.updateHub(
          id: editingHub!.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
        );
      }
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save hub: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _startEdit(Hub hub) {
    nameController.text = hub.name;
    descriptionController.text = hub.description;
    imagePath = null;
    editingHub = hub;
    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hub Admin')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileImagePicker(
                      imagePath: imagePath ?? editingHub?.imageUrl,
                      onImagePicked: (path) => setState(() => imagePath = path),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    editingHub == null
                                        ? 'Create Hub'
                                        : 'Save Changes',
                                  ),
                        ),
                        const SizedBox(width: 12),
                        if (editingHub != null)
                          TextButton(
                            onPressed: isLoading ? null : _resetForm,
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Hub>>(
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          tooltip: 'Edit Hub',
                          onPressed: () => _startEdit(hub),
                        ),
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
