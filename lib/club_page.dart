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

// what is shown on the sort dialog for user
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
  // variables that get updated when opening the club page
  List<Map<String, dynamic>> _members = [];
  int _memberCount = 0;
  // standard sort option until user changes it
  SortOption _currentSortOption = SortOption.addedFirstToLast;

  // load members when opening the club page
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
    // sort members, standard is first to last if user didnt change it
    _sortMembers();
  }

  // changes the sequence of members based on users choice
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
    // wait till create member dialog gets popped
    final memberData = await _createMemberDialog();
    // if user clicked add (instead of cancel)
    if (memberData != null) {
      await DatabaseHelper.instance.addMember(
        memberData['firstname']!,
        memberData['lastname']!,
        memberData['birthdate']!,
        widget.club['id'],
      );
      // update the list of members, considers the sorting choice
      _loadMembers();
    }
  }

  // shows dialog where user enters data about new member
  Future<Map<String, String>?> _createMemberDialog() async {
    String? memberFirstName;
    String? memberLastName;
    String? memberBirthdate;
    TextEditingController dateController = TextEditingController();

    // user needs to enter birthdate by date picker
    // so that its always in the right format and intuitive for user
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

    // this creates the actual dialog window
    return showDialog<Map<String, String>>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Add new member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Text field for first name
              TextField(
                onChanged: (value) {
                  memberFirstName = value;

                },
                decoration: const InputDecoration(hintText: 'First name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Text field for last name
              TextField(
                onChanged: (value) {
                  memberLastName = value;

                },
                decoration: const InputDecoration(hintText: 'Last name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Text field for birthdate
              TextField(
                controller: dateController,
                decoration: const InputDecoration(hintText: 'Birthdate'),
                readOnly: true,
                onTap: () async {
                  // opens date picker 
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      // format to YYYY-MM-DD
                      memberBirthdate = pickedDate.toIso8601String().split('T')[0];
                      dateController.text = memberBirthdate!;
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[

            // cancel button, closes add member dialog without doing anything
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }
            ),

            // Add button, closes dialog window and passes entered
            // data back to _newMember function 
            TextButton(
              child: const Text('Add'),
              // only clickable if all data was entered
              onPressed: () {
                if (memberFirstName != null && 
                    memberLastName != null && 
                    memberBirthdate != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'firstname': memberFirstName!, 
                    'lastname': memberLastName!, 
                    'birthdate': memberBirthdate!
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // dialog if user long presses on a specific user
  // option to cancel, edit data, delete the member from club
  Future<void> _removeOrEditDialog(Map<String, dynamic> member) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${member['firstname']} ${member['lastname']}'),
          content: Text('What do you want to do?'),
          actions: <Widget>[

            // cancel button, only closes dialog
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                HapticFeedback.mediumImpact();
              }
            ),

            // edit button, calls the _editMember function
            TextButton(
              child: const Text('Edit'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(); // close dialog
                _editMember(member);
              }
            ),

            // remove button, calls the _removeMember function
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
    // wait till edit member dialog gets popped
    final memberData = await _editMemberDialog(member);
    // enter new data in db if user clicked save (instead of cancel)
    if (memberData != null) {
      await DatabaseHelper.instance.editMember(
        member['id'],
        memberData['firstname']!,
        memberData['lastname']!,
        memberData['birthdate']!,
        member['clubId'],
      );
      // update the list of members, considers the sorting choice
      _loadMembers();
    }
  }

  Future<Map<String, String>?> _editMemberDialog(Map<String, dynamic> member) async {
    // create text controllers and prefill them with the current members data
    // so that text fields of dialog are already filled with the current members data
    // user doesnt have to interact with text fields where no change is wanted
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

              // Text field for first name
              TextField(
                controller: firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Text field for last name 
              TextField(
                controller: lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Text field for birthdate
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
                    // format to YYYY-MM-DD
                    birthdateController.text = pickedDate.toIso8601String().split('T')[0];
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[

            // cancel button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
            ),

            // save button, returns data to _editMember function
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // only clickable if all data is entered
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

              // cancel button
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                HapticFeedback.mediumImpact();
              }
            ),

            // remove button, deletes member from db
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(); // close dialog
                
                // delete member from db
                await DatabaseHelper.instance.deleteMember(member['id']);
                
                // update the members list
                _loadMembers();
              }
            ),
          ],
        );
      },
    );
  }

  // user can choose the sorting order of members
  Future<void> _sortMemberDialog() async {
    
    // when opening the dialog, the current sorting option is already checked
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
                // show all options as radio button list with their description 
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
            // cancel button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }, 
            ),

            // OK button, sets the selected sorting option
            // and reloads the members in new order
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

  // edit club data
  void _editClub() async {
    // waits till edit club dialog gets popped
    final clubData = await _editClubDialog();
    // change data in db if user clicked save (instead of cancel)
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

      // check if widget still exists
      if (mounted) {
        // reload the club page with new data
        Navigator.pushReplacement(context, 
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
  }

  // dialog for editing clubs
  Future<Map<String, String>?> _editClubDialog() async {
    // create text controllers and prefill them with the current club data
    // so that text fields of dialog are already filled with the current club data
    // user doesnt have to interact with text fields where no change is wanted
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
              // user picks color with color picker
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

              // cancel button
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                }
              ),

              // OK button, returns selected color to edit club dialog
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  setState((){
                    if (isPrimary) {
                      clubColor = pickedColor;
                      colorController.text = 
                        // ignore: deprecated_member_use
                        '#${clubColor.value.toRadixString(16).substring(2).toUpperCase()}';
                    }
                    else {
                      clubSecondColor = pickedColor;
                      colorSecondController.text = 
                        // ignore: deprecated_member_use
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

    // the actual edit club dialog
    return showDialog<Map<String, String>>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Edit club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // text field for club name
                TextField(
                  controller: clubNameController,
                  decoration: const InputDecoration(labelText: 'Club name'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                // text field for city
                TextField(
                  controller: clubCityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),

                // text field for founding year of club
                TextField(
                  controller: clubYearController,
                  decoration: const InputDecoration(labelText: 'Founding year'),
                  keyboardType: TextInputType.number,
                ),

                // text field for primary color
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Primary color'),
                  readOnly: true,
                  onTap: () => selectColor(context, true),
                ),

                // text field for secondary color
                TextField(
                  controller: colorSecondController,
                  decoration: const InputDecoration(labelText: 'Secondary color'),
                  readOnly: true,
                  onTap: () => selectColor(context, false),
                ),

                // text field for description
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
            
            // cancel button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
            ),

            // save button, returns data to _editClub function
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // only clickable if all data was entered
                if (clubNameController.text.isNotEmpty && 
                    clubCityController.text.isNotEmpty && 
                    clubYearController.text.isNotEmpty &&
                    colorController.text.isNotEmpty &&
                    colorSecondController.text.isNotEmpty) {
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
            ),
          ],
        );
      },
    );
  }

  // calculate age from birthdate
  int _calculateAge(String birthdateString) {
    DateTime todayDate = DateTime.now();
    DateTime birthDate = DateTime.parse(birthdateString);
    int age = todayDate.year - birthDate.year;

    if (todayDate.month < birthDate.month || 
       (todayDate.month == birthDate.month && todayDate.day < birthDate.day)) 
    {
      age--;
    }
    return age;
  }

  // transforms string hexcode back to a color
  Color hexToColor(String hex){
    hex = hex.replaceAll('#', '');
    hex = 'FF$hex'; // adding alpha value (no transparency)
    return Color(int.parse(hex, radix:16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // app bar is in club color, club name in secondary color
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

                // edit club button
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
            // show only if user entered a description
            if (widget.club['description'].isNotEmpty) ... [
              const SizedBox(height: 8),
              Text('📝 Description: \n${widget.club['description']}', style: const TextStyle(fontSize: 18)),
            ],            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Member List:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                
                // change sorting button
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
              ? const Text('Club has no members yet') // text if club is empty
              : ListView.builder(
              itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Column(
                    children: [
                      // list with all members, shows their name and age
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
        tooltip: 'Add new member to ${widget.club['name']}',
        child: const Icon(Icons.add),
      ),
    );
  }
}