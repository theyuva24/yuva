import 'package:flutter/material.dart';
import '../model/challenge_model.dart';

class SubmitEntryPage extends StatelessWidget {
  final Challenge challenge;
  const SubmitEntryPage({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Entry')),
      body: Center(
        child: Text('Submission form for \\${challenge.title} will go here.'),
      ),
    );
  }
}
