import 'package:flutter/material.dart';

class ClubPage extends StatelessWidget {
  
  final Map<String, dynamic> club;

  const ClubPage({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(club['name']), // Club-Name als Titel der AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏙 City: ${club['city']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('📅 Founded: ${club['year']}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}