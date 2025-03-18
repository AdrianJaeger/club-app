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
  // variables
  List<Map<String, dynamic>> _clubs = [];

  // load existing clubs from db when opening the app
  @override
  void initState(){
    super.initState();
    _loadClubs();
  }

  // load clubs in database to show them in list on screen
  void _loadClubs() async {
    final clubs = await DatabaseHelper.instance.getClubs();
    setState(() {
      _clubs = clubs;
    });
  }

  // add a new club to db
  void _newClub() async {
    final clubData = await _createClubDialog();
    if (clubData != null && clubData['name']!.isNotEmpty) {
      int id = await DatabaseHelper.instance.addClub(
        clubData['name']!, 
        clubData['city']!,
        clubData['year']!,
        clubData['color']!,
        clubData['secondcolor']!,
        clubData['description']!,
      );
      debugPrint('New club added with ID: $id');
      debugPrint('Club data: $clubData');
      _loadClubs();
    }
  }

  // Dialog for adding clubs
  Future<Map<String, String>?> _createClubDialog() async {
    String? clubName;
    String? clubCity;
    String? clubYear;
    Color clubColor = Colors.blue;
    Color clubSecondColor = Colors.black;
    TextEditingController colorController = TextEditingController();
    TextEditingController colorSecondController = TextEditingController();
    String? clubDescription;

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
          title: const Text('Create a new club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    clubName = value;
                  },
                  decoration: const InputDecoration(hintText: 'Club name'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  onChanged: (value) {
                    clubCity = value;
                  },
                  decoration: const InputDecoration(hintText: 'City of club'),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  onChanged: (value) {
                    clubYear = value;
                  },
                  decoration: const InputDecoration(hintText: 'Founding year of club'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(hintText: 'Primary club color'),
                  readOnly: true,
                  onTap: () => selectColor(context, true),
                ),
                TextField(
                  controller: colorSecondController,
                  decoration: const InputDecoration(hintText: 'Secondary club color'),
                  readOnly: true,
                  onTap: () => selectColor(context, false),
                ),
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
            TextButton(
              onPressed: () {
                if (clubName != null && clubName!.isNotEmpty && 
                    clubCity != null && clubCity!.isNotEmpty &&
                    clubYear != null && clubYear!.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop({
                    'name': clubName ?? '',
                    'city': clubCity ?? '',
                    'year': clubYear ?? '',
                    'color': '#${clubColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    'secondcolor': '#${clubSecondColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    'description': clubDescription ?? '',
                });
                }
              },
              child: const Text('Create'),
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
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                HapticFeedback.mediumImpact();
              }
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                // delete club from db
                await DatabaseHelper.instance.deleteClub(club['id']);
                // update the clubs list
                _loadClubs();
                Navigator.of(context).pop(); // close dialog
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
          ? const Text('No clubs exist yet')
          : ListView.builder(
              itemCount: _clubs.length,
              itemBuilder: (context, index) {
                final club = _clubs[index];
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClubPage(club: club),
                          )
                        );
                        HapticFeedback.mediumImpact();
                      },
                      onLongPress: () {
                        _removeClubDialog(club);
                        HapticFeedback.mediumImpact();
                      },
                      child:
                        ListTile(
                        title: Text(_clubs[index]['name']),
                        subtitle: Text(club['year']),
                      ),
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