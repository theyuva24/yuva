import 'package:flutter/material.dart';
import '../service/challenge_service.dart';
import '../widget/challenge_card.dart';
import '../model/challenge_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final ChallengeService _challengeService = ChallengeService();
  late Future<List<Challenge>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = _challengeService.fetchAllChallenges();
  }

  void _refreshChallenges() {
    setState(() {
      _challengesFuture = _challengeService.fetchAllChallenges(
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeLight.background,
      // Removed the AppBar as requested
      body: RefreshIndicator(
        onRefresh: () async => _refreshChallenges(),
        child: FutureBuilder<List<Challenge>>(
          future: _challengesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppThemeLight.primary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading challenges...',
                            style: TextStyle(
                              color: AppThemeLight.primary,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppThemeLight.primary,
                            size: 48,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: AppThemeLight.primary,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: _refreshChallenges,
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: AppThemeLight.primary,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            final challenges = snapshot.data ?? [];
            if (challenges.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            color: AppThemeLight.primary,
                            size: 48,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No challenges available yet.',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: AppThemeLight.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: challenges.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                return ChallengeCard(challenge: challenges[index]);
              },
            );
          },
        ),
      ),
      // FAB removed
    );
  }
}
