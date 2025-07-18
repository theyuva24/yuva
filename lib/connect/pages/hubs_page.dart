import 'package:flutter/material.dart';
import '../models/hub_model.dart';
import '../service/hub_service.dart';
import 'hub_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';

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
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: const Text(
                'Create Hub',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
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
                      SizedBox(height: 16.h),
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
                          ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                          : Text('Create', style: TextStyle(fontSize: 16.sp)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        centerTitle: true,
        title: Text(
          'Hubs',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      // FAB for adding a hub is intentionally hidden as per request
      body: StreamBuilder<List<Hub>>(
        stream: hubService.getHubsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppThemeLight.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading hubs',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            );
          }
          final hubs = snapshot.data ?? [];
          if (hubs.isEmpty) {
            return Center(
              child: Text(
                'No hubs available.',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            );
          }
          return ListView.builder(
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final hub = hubs[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppThemeLight.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppThemeLight.border, width: 1.5.w),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeLight.primary.withOpacity(0.08),
                      blurRadius: 8.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppThemeLight.primary,
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeLight.primary.withOpacity(0.12),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(hub.imageUrl),
                      backgroundColor: AppThemeLight.background,
                    ),
                  ),
                  title: Text(
                    hub.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    hub.description,
                    style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}
