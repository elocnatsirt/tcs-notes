import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() {
  runApp(MaterialApp(
    title: 'TC\'s Notes',
    home: MyApp(),
  ));
}

final fakeNotes = List<Note>.generate(
  20,
  (i) => Note(
    'Note $i',
    'Body of note $i',
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TC\'s Notes',
      home: Scaffold(
        appBar: AppBar(
          title: Text('TC\'s Notes'),
        ),
        body: Center(
          child: ListView.builder(
              itemCount: fakeNotes.length,
              itemBuilder: (context, index) {
                return Slidable(
                  actionPane: SlidableDrawerActionPane(),
                  child: ListTile(
                    title: Text('${fakeNotes[index].title}'),
                    subtitle: Text('${fakeNotes[index].body}'),
                    leading: Icon(Icons.note, size: 56),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ViewNote(note: fakeNotes[index])));
                    },
                  ),
                  secondaryActions: [
                    IconSlideAction(
                        caption: 'Edit',
                        color: Colors.blue,
                        icon: Icons.edit,
                        onTap: () {
                          print('editing list tile');
                        }),
                    IconSlideAction(
                        caption: 'Delete',
                        color: Colors.red,
                        icon: Icons.delete,
                        onTap: () {
                          print('deleting list tile');
                        }),
                  ],
                );
              }),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NoteForm()),
            );
          },
          tooltip: 'Add Note',
          label: Text('New Note'),
          icon: Icon(Icons.note_add),
        ),
      ),
    );
  }
}

// View Note Widget

class Note {
  final String title;
  final String body;

  Note(this.title, this.body);
}

class ViewNote extends StatelessWidget {
  final Note note;
  ViewNote({Key key, @required this.note}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(note.title),
        ),
        body: Text(note.body));
  }
}

// Add Note Form Widget
class NoteForm extends StatefulWidget {
  @override
  AddNote createState() {
    return AddNote();
  }
}

class AddNote extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("New Note"),
        ),
        body: Center(
            child: Container(
                child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(minWidth: 300, maxWidth: 960),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a name for your note';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(),
                        hintText: 'Enter the name of your note',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter a body for your note';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.note_add),
                          border: OutlineInputBorder(),
                          hintText: 'Write your note',
                          isDense: true,
                          contentPadding: EdgeInsets.all(10),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        minLines: 4),
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              FlatButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                    color: Colors.green,
                    width: 300,
                    height: 100,
                    child: Center(
                        child: Text(
                      'Save Note',
                      style: TextStyle(fontSize: 25),
                    ))),
              ),
            ],
          ),
        ))));
  }
}
