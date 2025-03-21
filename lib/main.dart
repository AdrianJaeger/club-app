import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'database_helper.dart';
import 'club_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {    
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club Administration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 80, 156, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Clubs'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _clubs = [];

  // load existing clubs from db when opening the app
  @override
  void initState(){
    super.initState();
    _loadClubs();
  }

  // load clubs from database to show them in list on screen
  void _loadClubs() async {
    final clubs = await DatabaseHelper.instance.getClubs();
    setState(() {
      _clubs = clubs;
    });
  }

  // add a new club to db
  void _newClub() async {
    // open dialog to enter all the data for the club
    final clubData = await _createClubDialog();

    // clubdata is null if user clicks "cancel" on create club dialog
    // so this gets only executed after user clicked "create"
    if (clubData != null && clubData['name']!.isNotEmpty) {
      // add new club with entered data to db
      await DatabaseHelper.instance.addClub(
        clubData['name']!, 
        clubData['city']!,
        clubData['year']!,
        clubData['color']!,
        clubData['secondcolor']!,
        clubData['description']!,
      );
      // refresh list of clubs after adding one to db
      _loadClubs();
    }
  }

  // dialog for creating clubs
  Future<Map<String, String>?> _createClubDialog() async {
    String? clubName;
    String? clubCity;
    String? clubYear;
    String? clubDescription;
    Color clubColor = Colors.blue;
    Color clubSecondColor = Colors.black;
    TextEditingController colorController = TextEditingController();
    TextEditingController colorSecondController = TextEditingController();

    // this is for selecting the primary and secondary color
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

              // cancel button, closes color picker window
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                }
              ),

              // OK button, saves the selected color for create club dialog 
              // and closes color picker window
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  setState((){
                    if (isPrimary) {
                      // save the selected club color for db
                      clubColor = pickedColor;
                      // hex representation of this color for the text field on dialog
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

    // this creates the actual dialog window
    return showDialog<Map<String, String>>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Create a new club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Text field for club name
                TextField(
                  onChanged: (value) {
                    clubName = value;
                  },
                  decoration: const InputDecoration(hintText: 'Club name'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),

                // Text field for city of club
                TextField(
                  onChanged: (value) {
                    clubCity = value;
                  },
                  decoration: const InputDecoration(hintText: 'City of club'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),

                // Text field for founding year of club
                TextField(
                  onChanged: (value) {
                    clubYear = value;
                  },
                  decoration: const InputDecoration(hintText: 'Founding year of club'),
                  keyboardType: TextInputType.number,
                ),

                // Text field for primary color of club
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(hintText: 'Primary club color'),
                  readOnly: true,
                  onTap: () => selectColor(context, true),
                ),

                // Text field for secondary color of club
                TextField(
                  controller: colorSecondController,
                  decoration: const InputDecoration(hintText: 'Secondary club color'),
                  readOnly: true,
                  onTap: () => selectColor(context, false),
                ),

                // Text field for club description
                TextField(
                  onChanged: (value) {
                    clubDescription = value;
                  },
                  decoration: const InputDecoration(hintText: 'Description, optional'),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // cancel button, closes create club dialog without doing anything
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }
            ),

            // create button
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                // only works if user selected everything except description
                if (clubName != null && clubName!.isNotEmpty && 
                    clubCity != null && clubCity!.isNotEmpty &&
                    clubYear != null && clubYear!.isNotEmpty &&
                    colorController.text.isNotEmpty &&
                    colorSecondController.text.isNotEmpty) {

                  HapticFeedback.mediumImpact();

                  // returns all entered data to _newClub function that creates the club in database
                  Navigator.of(context).pop({
                    'name': clubName ?? '',
                    'city': clubCity ?? '',
                    'year': clubYear ?? '',
                    'color': colorController.text,
                    'secondcolor': colorSecondController.text,
                    'description': clubDescription ?? '',
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // show a dialog to confirm the deletion of a club
  Future<void> _removeClubDialog(Map<String, dynamic> club) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete club'),
          content: Text('Are you sure you want to delete ${club['name']}?'),
          actions: <Widget>[

            // cancel button, just closes dialog
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                HapticFeedback.mediumImpact();
              }
            ),

            // delete button, deletes club and all its members from db
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(); // close dialog

                // update the clubs list
                _loadClubs();
                
                // delete club from db
                await DatabaseHelper.instance.deleteClub(club['id']);
              }
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
        backgroundColor: Colors.blue[900],
        title: Text(
            widget.title,
            style: TextStyle(color: Colors.white)
        ),
        centerTitle: true,
      ),
      // list with all existing clubs
      body: Center(
        child: _clubs.isEmpty
          ? const Text('No clubs exist yet') // if list of clubs is empty, show this text
          : ListView.builder(
              itemCount: _clubs.length,
              itemBuilder: (context, index) {
                final club = _clubs[index];
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // open the club page 
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          
                          // delay for opening club page so that user see click animation
                          await Future.delayed(const Duration (milliseconds: 100));
                          
                          if (mounted) {
                            // context is in a mounted check so warning is useless
                            // ignore: use_build_context_synchronously
                            await Navigator.push(context, 
                              MaterialPageRoute(
                                builder: (context) => ClubPage(club: club),
                              ),
                            );

                            // refreshes the clubs after returning to home, in case a clubs data was edited 
                            _loadClubs();
                          }
                        },

                        // open dialog for deleting a club from db
                        onLongPress: () {
                          _removeClubDialog(club);
                          HapticFeedback.mediumImpact();
                        },

                        // every club in list shows its name and founding year
                        child: ListTile(
                          title: Text(_clubs[index]['name']),
                          subtitle: Text(club['year']),
                        ),

                      )
                    ),
                  const Divider(),
                  ],
                );
              },
            ), 
      ),

      // button to add new clubs
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newClub();
          HapticFeedback.mediumImpact();
        },
        tooltip: 'Add new club',
        child: const Icon(Icons.add),
      ),
    );
  }
}