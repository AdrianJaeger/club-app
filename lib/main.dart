import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart'; // import of database class

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
    final name = await _addClubDialog();
    if (name != null && name.isNotEmpty) {
      await DatabaseHelper.instance.addClub(name);
      _loadClubs();
    }
  }

  // Dialog for adding clubs
  Future<String?> _addClubDialog() async {
    String? clubName;
    return showDialog<String>(
      context: context,
      builder:(context) {
        return AlertDialog(
          title: const Text('Add new club'),
          content:TextField(
            onChanged: (value) {
              clubName = value;
            },
            decoration: const InputDecoration(hintText: 'Club name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(clubName);
              },
              child: const Text('Add'),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
                      // onTap: () => _openClub(club),
                      onLongPress: () {
                        _removeClubDialog(club);
                        HapticFeedback.mediumImpact();
                      },
                      child:
                        ListTile(
                        title: Text(_clubs[index]['name']),
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