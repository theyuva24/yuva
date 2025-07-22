import 'package:flutter/material.dart';
import '../models/hub_model.dart';
import '../service/hub_service.dart';
import 'hub_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [Tab(text: 'Popular'), Tab(text: 'Joined')],
          ),
        ),
        body: TabBarView(
          children: [
            // Popular Hubs Tab (sorted by popularityScore)
            StreamBuilder<List<String>>(
              stream: hubService.getJoinedHubsStream(),
              builder: (context, joinedHubsSnapshot) {
                if (joinedHubsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeLight.primary,
                    ),
                  );
                }

                final joinedHubIds = joinedHubsSnapshot.data ?? [];

                return StreamBuilder<List<Hub>>(
                  stream: hubService.getHubsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppThemeLight.primary,
                        ),
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

                    // Sort hubs by popularityScore (descending)
                    final sortedHubs = List<Hub>.from(hubs);
                    sortedHubs.sort((a, b) {
                      final scoreA = a.popularityScore ?? 0;
                      final scoreB = b.popularityScore ?? 0;
                      return scoreB.compareTo(scoreA); // Descending order
                    });

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: sortedHubs.length,
                      itemBuilder: (context, index) {
                        final hub = sortedHubs[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HubDetailsPage(hub: hub),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.only(bottom: 16.h),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: CachedNetworkImage(
                                      imageUrl: hub.imageUrl,
                                      width: 64.w,
                                      height: 64.w,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 64.w,
                                            height: 64.w,
                                            color: AppThemeLight.surface,
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 32.w,
                                              color: AppThemeLight.primary
                                                  .withAlpha(76),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: 64.w,
                                            height: 64.w,
                                            color: AppThemeLight.surface,
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 32.w,
                                              color: AppThemeLight.primary
                                                  .withAlpha(76),
                                            ),
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                hub.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (joinedHubIds.contains(
                                              hub.id,
                                            )) // Only show if user has joined this hub
                                              Container(
                                                margin: EdgeInsets.only(
                                                  left: 8.w,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppThemeLight.primary
                                                      .withAlpha(25),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Joined',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppThemeLight
                                                                .primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          hub.description,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            // Joined Hubs Tab (filtered to show only joined hubs)
            StreamBuilder<List<String>>(
              stream: hubService.getJoinedHubsStream(),
              builder: (context, joinedHubsSnapshot) {
                if (joinedHubsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeLight.primary,
                    ),
                  );
                }

                final joinedHubIds = joinedHubsSnapshot.data ?? [];

                return StreamBuilder<List<Hub>>(
                  stream: hubService.getHubsStream(),
                  builder: (context, allHubsSnapshot) {
                    if (allHubsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppThemeLight.primary,
                        ),
                      );
                    }
                    if (allHubsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading hubs',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      );
                    }

                    final allHubs = allHubsSnapshot.data ?? [];
                    final joinedHubs =
                        allHubs
                            .where((hub) => joinedHubIds.contains(hub.id))
                            .toList();

                    if (joinedHubs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 64.w,
                              color: AppThemeLight.primary.withAlpha(128),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'You haven\'t joined any hubs yet.',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppThemeLight.primary.withAlpha(179),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Join hubs from the Popular tab to see them here!',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppThemeLight.primary.withAlpha(128),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: joinedHubs.length,
                      itemBuilder: (context, index) {
                        final hub = joinedHubs[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HubDetailsPage(hub: hub),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.only(bottom: 16.h),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: CachedNetworkImage(
                                      imageUrl: hub.imageUrl,
                                      width: 64.w,
                                      height: 64.w,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 64.w,
                                            height: 64.w,
                                            color: AppThemeLight.surface,
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 32.w,
                                              color: AppThemeLight.primary
                                                  .withAlpha(76),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: 64.w,
                                            height: 64.w,
                                            color: AppThemeLight.surface,
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 32.w,
                                              color: AppThemeLight.primary
                                                  .withAlpha(76),
                                            ),
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                hub.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (joinedHubs !=
                                                null) // For Joined tab only
                                              Container(
                                                margin: EdgeInsets.only(
                                                  left: 8.w,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppThemeLight.primary
                                                      .withAlpha(25),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Joined',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppThemeLight
                                                                .primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          hub.description,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
