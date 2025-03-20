import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'database_helper.dart';

class ClubPage extends StatefulWidget {
  final Map<String, dynamic> club;
  const ClubPage({super.key, required this.club});

    @override
  State<ClubPage> createState() => _ClubPageState();
}

// possibilities how to sort the members
enum SortOption {nameAToZ, nameZToA, ageYoungToOld, ageOldToYoung, addedLastToFirst, addedFirstToLast}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch(this) {
      case SortOption.nameAToZ:
        return 'Last name, A to Z';
      case SortOption.nameZToA:
        return 'Last name, Z to A';
      case SortOption.ageYoungToOld:
        return 'Age, ascending';
      case SortOption.ageOldToYoung:
        return 'Age, descending';
      case SortOption.addedLastToFirst:
        return 'Added to club, last to first';
      case SortOption.addedFirstToLast:
        return 'Added to club, first to last';
      
    }
  }
}

class _ClubPageState extends State<ClubPage> {
  // variables
  List<Map<String, dynamic>> _members = [];
  int _memberCount = 0;
  SortOption _currentSortOption = SortOption.addedFirstToLast;

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
    _sortMembers();
  }

  void _sortMembers() {
    setState(() {
      _members = List<Map<String, dynamic>>.from(_members);

      _members.sort((a,b) {
        switch (_currentSortOption) {
          case SortOption.nameAToZ:
            return a['lastname'].compareTo(b['lastname']);
          case SortOption.nameZToA:
            return b['lastname'].compareTo(a['lastname']);
          case SortOption.ageYoungToOld:
            return b['birthdate'].compareTo(a['birthdate']);
          case SortOption.ageOldToYoung:
            return a['birthdate'].compareTo(b['birthdate']);
          case SortOption.addedLastToFirst:
            return b['id'].compareTo(a['id']);
          case SortOption.addedFirstToLast:
            return a['id'].compareTo(b['id']);
        }
      });
    });
  }

  // add a new member to db
  void _newMember() async {
    final memberData = await _createMemberDialog();
    if (memberData != null) {
      await DatabaseHelper.instance.addMember(
        memberData['firstname']!,
        memberData['lastname']!,
        memberData['birthdate']!,
        widget.club['id'],
      );
      _loadMembers();
    }
  }

  Future<Map<String, String>?> _createMemberDialog() async {
    String? memberFirstName;
    String? memberLastName;
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
                  memberFirstName = value;

                },
                decoration: const InputDecoration(hintText: 'First name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                onChanged: (value) {
                  memberLastName = value;

                },
                decoration: const InputDecoration(hintText: 'Last name'),
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
                if (memberFirstName != null && memberLastName != null && memberBirthdate != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'firstname': memberFirstName!, 
                    'lastname': memberLastName!, 
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

  Future<void> _removeOrEditDialog(Map<String, dynamic> member) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${member['firstname']} ${member['lastname']}'),
          content: Text('What do you want to do?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                HapticFeedback.mediumImpact();
              }
            ),
            TextButton(
              child: const Text('Edit'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(); // close dialog
                _editMember(member);
              }
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(); // close dialog
                _removeMemberDialog(member);
              }
            ),
          ],
        );
      },
    );
  }

  // edit member in database
  void _editMember(Map<String, dynamic> member) async {
    final memberData = await _editMemberDialog(member);
    if (memberData != null) {
      await DatabaseHelper.instance.editMember(
        member['id'],
        memberData['firstname']!,
        memberData['lastname']!,
        memberData['birthdate']!,
        member['clubId'],
      );
      _loadMembers(); // reload the member list
    }
  }

  Future<Map<String, String>?> _editMemberDialog(Map<String, dynamic> member) async {
    // create text controllers and pre-fill them with the current member's data
    TextEditingController firstnameController = TextEditingController(text: member['firstname']);
    TextEditingController lastnameController = TextEditingController(text: member['lastname']);
    TextEditingController birthdateController = TextEditingController(text: member['birthdate']);
    
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: birthdateController,
                decoration: const InputDecoration(labelText: 'Birthdate (YYYY-MM-DD)'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );

                  if (pickedDate != null) {
                    birthdateController.text = pickedDate.toIso8601String().split('T')[0]; // Format to YYYY-MM-DD
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (firstnameController.text.isNotEmpty &&
                    lastnameController.text.isNotEmpty &&
                    birthdateController.text.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'firstname': firstnameController.text,
                    'lastname': lastnameController.text,
                    'birthdate': birthdateController.text,
                  });
                }
              },
              child: const Text('Save'),
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
          content: Text('Are you sure you want to remove ${member['firstname']} ${member['lastname']}?'),
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

  Future<void> _sortMemberDialog() async {
    SortOption selectedOption = _currentSortOption;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort Members'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: SortOption.values.map((option){
                  return RadioListTile<SortOption>(
                    title: Text(option.displayName),
                    value: option, 
                    groupValue: selectedOption, 
                    onChanged: (value) {
                      setState((){
                        selectedOption = value!;
                      });
                    },
                  );
                }).toList(),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }, 
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _currentSortOption = selectedOption;
                _sortMembers();
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }, 
              child: const Text('OK'),
            )
          ]
        );
      },
    );
  }

  // edit club in database
  void _editClub() async {
    final clubData = await _editClubDialog();
    if (clubData != null) {
      await DatabaseHelper.instance.editClub(
        widget.club['id'],
        clubData['name']!, 
        clubData['city']!,
        clubData['year']!,
        clubData['color']!,
        clubData['secondcolor']!,
        clubData['description']!,
      );
      // reload the club page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClubPage(club: {
            'id': widget.club['id'],
            'name': clubData['name']!,
            'city': clubData['city']!,
            'year': clubData['year']!,
            'color': clubData['color']!,
            'secondcolor': clubData['secondcolor']!,
            'description': clubData['description']!,
          }),
        ),
      );
    }
  }

  // dialog for editing clubs
  Future<Map<String, String>?> _editClubDialog() async {
    // get current values from db
    TextEditingController clubNameController = TextEditingController(text: widget.club['name']);
    TextEditingController clubCityController = TextEditingController(text: widget.club['city']);
    TextEditingController clubYearController = TextEditingController(text: widget.club['year'].toString());
    TextEditingController clubDescriptionController = TextEditingController(text: widget.club['description'] ?? '');
    
    Color clubColor = hexToColor(widget.club['color']);
    Color clubSecondColor = hexToColor(widget.club['secondcolor']);
    TextEditingController colorController = TextEditingController(text: widget.club['color']);
    TextEditingController colorSecondController = TextEditingController(text: widget.club['secondcolor']);

    Future<void> selectColor(BuildContext context, bool isPrimary) async {
      Color pickedColor = isPrimary ? clubColor : clubSecondColor;
      await showDialog<Color>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick a color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickedColor, 
                onColorChanged: (color){
                  pickedColor = color;
                },
                enableAlpha: false,
                pickerAreaBorderRadius: BorderRadius.circular(8),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                }
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  setState((){
                    if (isPrimary) {
                      clubColor = pickedColor;
                      colorController.text = 
                        '#${clubColor.value.toRadixString(16).substring(2).toUpperCase()}';
                    }
                    else {
                      clubSecondColor = pickedColor;
                      colorSecondController.text = 
                        '#${clubSecondColor.value.toRadixString(16).substring(2).toUpperCase()}';
                    }
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                  });
                } 
              )
            ],
          );
        },
      );
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Edit club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clubNameController,
                  decoration: const InputDecoration(labelText: 'Club name'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: clubCityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: clubYearController,
                  decoration: const InputDecoration(labelText: 'Founding year'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Primary color'),
                  readOnly: true,
                  onTap: () => selectColor(context, true),
                ),
                TextField(
                  controller: colorSecondController,
                  decoration: const InputDecoration(labelText: 'Secondary color'),
                  readOnly: true,
                  onTap: () => selectColor(context, false),
                ),
                TextField(
                  controller: clubDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
            TextButton(
              onPressed: () {
                if (clubNameController.text.isNotEmpty && 
                    clubCityController.text.isNotEmpty && 
                    clubYearController.text.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'name': clubNameController.text,
                    'city': clubCityController.text,
                    'year': clubYearController.text,
                    'color': colorController.text,
                    'secondcolor': colorSecondController.text,
                    'description': clubDescriptionController.text,
                });
                }
              },
              child: const Text('Save'),
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

  Color hexToColor(String hex){
    hex = hex.replaceAll('#', '');
    hex = 'FF$hex'; // adding alpha value (no transparency)
    return Color(int.parse(hex, radix:16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: hexToColor(widget.club['color']),
        title: Text(
            widget.club['name'],
            style: TextStyle(color: hexToColor(widget.club['secondcolor']))
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🏙 City: ${widget.club['city']}', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _editClub();
                  }, 
                ),
              ],
            ),
            Text('📅 Founded: ${widget.club['year']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('👥 Members: $_memberCount', style: const TextStyle(fontSize: 18)),
            // show only if there is a description
            if (widget.club['description'].isNotEmpty) ... [
              const SizedBox(height: 8),
              Text('📝 Description: \n${widget.club['description']}', style: const TextStyle(fontSize: 18)),
            ],            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Member List:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _sortMemberDialog();
                  }, 
                ),
              ],
            ),
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
                      ListTile(
                        title: Text('${member['firstname']} ${member['lastname']}'),
                        subtitle: Text('Age: ${_calculateAge(member['birthdate'])} years'),
                        onLongPress: () {
                          _removeOrEditDialog(member);
                          HapticFeedback.mediumImpact();
                        },
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