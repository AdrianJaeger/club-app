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
        memberData['birthdate']!,
        widget.club['id'],
      );
      _loadMembers();
    }
  }

  Future<Map<String, String>?> _createMemberDialog() async {
    String? memberName;
    String? memberBirthdate;
    TextEditingController dateController = TextEditingController();

    Future<void> selectDate(BuildContext context) async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (pickedDate != null) {
        setState(() {
          memberBirthdate = pickedDate.toIso8601String().split('T')[0]; //YYYY-MM-DD ;
          dateController.text = memberBirthdate!;
        });
      }
    }

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
                controller: dateController,
                decoration: const InputDecoration(hintText: 'Birthdate'),
                readOnly: true,
                onTap: () => selectDate(context),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (memberName != null && memberBirthdate != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'name': memberName!, 
                    'birthdate': memberBirthdate!
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

  // show a dialog to confirm to remove a member
  Future<void> _removeMemberDialog(Map<String, dynamic> member) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove member'),
          content: Text('Are you sure you want to remove ${member['name']}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                HapticFeedback.mediumImpact();
              }
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                // delete member from db
                await DatabaseHelper.instance.deleteMember(member['id']);
                // update the members list
                _loadMembers();
                Navigator.of(context).pop(); // close dialog
              }
            ),
          ],
        );
      },
    );
  }

  int _calculateAge(String birthdateString) {
    DateTime todayDate = DateTime.now();
    DateTime birthDate = DateTime.parse(birthdateString);
    int age = todayDate.year - birthDate.year;

    if (todayDate.month < birthDate.month || 
        todayDate.month == birthDate.month && todayDate.day < birthDate.day) 
    {
      age--;
    }

    return age;
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
            // show only if there is a description
            if (widget.club['description'].isNotEmpty) ... [
              const SizedBox(height: 8),
              Text('Description: \n${widget.club['description']}', style: const TextStyle(fontSize: 18)),
            ],            
            const SizedBox(height: 16),
            const Text('Member List:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _members.isEmpty
              ? const Text('Club has no members yet')
              : ListView.builder(
              itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Column(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          _removeMemberDialog(member);
                          HapticFeedback.mediumImpact();
                        },
                        child:
                          ListTile(
                            title: Text(member['name']),
                            subtitle: Text('Age: ${_calculateAge(member['birthdate'])} years'),
                          ),
                      ),
                      const Divider(),
                    ],
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