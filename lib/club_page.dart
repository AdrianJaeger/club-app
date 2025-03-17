import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:flutter/services.dart';

class ClubPage extends StatefulWidget {
  final Map<String, dynamic> club;
  const ClubPage({super.key, required this.club});

    @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  // variables
  List<Map<String, dynamic>> _members = [];
  int _memberCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // load members of this club
  void _loadMembers() async {
    final members = await DatabaseHelper.instance.getMembers(widget.club['id']);
    setState(() {
      _members = members;
      _memberCount = members.length;
    });
  }

  // add a new member to db
  void _newMember() async {
    final memberData = await _createMemberDialog();
    if (memberData != null && memberData['name']!.isNotEmpty) {
      await DatabaseHelper.instance.addMember(
        memberData['name']!,
        int.parse(memberData['age']!),
        widget.club['id'],
      );
      _loadMembers();
    }
  }

  Future<Map<String, String>?> _createMemberDialog() async {
    String? memberName;
    String? memberAge;

    return showDialog<Map<String, String>>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Add new member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  memberName = value;

                },
                decoration: const InputDecoration(hintText: 'Member name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                onChanged: (value) {
                  memberAge = value;
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Age'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (memberName != null && memberAge != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'name': memberName!, 
                    'age': memberAge!
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club['name']), // club name as title of page
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏙 City: ${widget.club['city']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('📅 Founded: ${widget.club['year']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('👥 Members: $_memberCount', style: const TextStyle(fontSize: 18)),
            if (widget.club['description'].isNotEmpty) ... [
              const SizedBox(height: 8),
              Text('Description: \n${widget.club['description']}', style: const TextStyle(fontSize: 18)),
            ],            
            const SizedBox(height: 16),
            const Text('Member List:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return ListTile(
                    title: Text(member['name']),
                    subtitle: Text('Age: ${member['age']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // button to add new members
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newMember();
          HapticFeedback.mediumImpact();
        },
        tooltip: 'Add new member to $widget.club',
        child: const Icon(Icons.add),
      ),
    );
  }
}