import 'package:flutter/material.dart';
import '../service/challenge_service.dart';
import '../widget/challenge_card.dart';
import '../model/challenge_model.dart';

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
      _challengesFuture = _challengeService.fetchAllChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Center(
                      child: Column(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading challenges...'),
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
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: \\${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _refreshChallenges,
                            child: const Text('Retry'),
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
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No challenges available yet.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: challenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return ChallengeCard(challenge: challenges[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    // TODO: Only show for admins if needed
    return FloatingActionButton(
      onPressed: () {
        // TODO: Implement add challenge flow
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add Challenge (admin only) coming soon!'),
          ),
        );
      },
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.add),
      tooltip: 'Add Challenge',
    );
  }
}
