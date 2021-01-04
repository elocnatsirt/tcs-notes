import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  var notesBox = await Hive.openBox('notesBox');
  if (notesBox.length < 1) {
    notesBox.putAll({
      'My Note': 'This is my first note!',
    });
  }
  runApp(MaterialApp(
    title: 'TC\'s Notes',
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final notesBox = Hive.box('notesBox');
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TC\'s Notes',
        home: WillPopScope(
          onWillPop: () {
            return Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyApp(),
              ),
            );
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('TC\'s Notes'),
            ),
            body: Center(
              child: ListView.builder(
                  itemCount: notesBox.length,
                  itemBuilder: (context, index) {
                    var fullNote = Note(notesBox.keyAt(index).toString(),
                        notesBox.get(notesBox.keyAt(index)).toString());
                    var previewText =
                        notesBox.get(notesBox.keyAt(index)).toString();
                    if (previewText.length > 25) {
                      previewText = previewText.replaceRange(
                          25, previewText.length, '...');
                    }
                    return Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      child: ListTile(
                        title: Text(notesBox.keyAt(index).toString()),
                        subtitle: Text(previewText),
                        leading: Icon(Icons.note, size: 56),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ViewNote(note: fullNote)));
                        },
                      ),
                      secondaryActions: [
                        IconSlideAction(
                            caption: 'Edit',
                            color: Colors.blue,
                            icon: Icons.edit,
                            onTap: () {
                              print('editing list tile');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NoteForm(note: fullNote)),
                              );
                            }),
                        IconSlideAction(
                            caption: 'Delete',
                            color: Colors.red,
                            icon: Icons.delete,
                            onTap: () {
                              print('deleting list tile');
                              notesBox.delete(notesBox.keyAt(index));
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyApp(),
                                ),
                              );
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
        ));
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
    void handleClick(String value) {
      switch (value) {
        case 'Edit':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteForm(note: note)),
          );
          break;
        case 'Delete':
          print('deleting list tile');
          var notesBox = Hive.box('notesBox');
          notesBox.delete(note.title);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyApp(),
            ),
          );
          break;
      }
    }

    return WillPopScope(
        onWillPop: () {
          return Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyApp(),
            ),
          );
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(note.title),
              actions: <Widget>[
                PopupMenuButton<String>(
                  onSelected: handleClick,
                  itemBuilder: (BuildContext context) {
                    return {'Edit', 'Delete'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            body: Text(note.body)));
  }
}

// Add Note Form Widget
class NoteForm extends StatefulWidget {
  final Note note;
  NoteForm({Key key, this.note}) : super(key: key);
  @override
  AddNote createState() {
    return AddNote();
  }
}

class AddNote extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  var noteTitleController = TextEditingController();
  var noteBodyController = TextEditingController();
  final notesBox = Hive.box('notesBox');
  var pageTitle = Text("New Note");

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    noteTitleController.dispose();
    noteBodyController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (widget.note != null) {
      noteTitleController =
          TextEditingController(text: widget.note.title.toString());
      noteBodyController =
          TextEditingController(text: widget.note.body.toString());
      pageTitle = Text("Edit Note");
    }
    return WillPopScope(
        onWillPop: () {
          return Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyApp(),
            ),
          );
        },
        child: Scaffold(
            appBar: AppBar(
              title: pageTitle,
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
                          controller: noteTitleController,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter a name for your note.';
                            } else if (widget.note == null &&
                                notesBox.get(value) != null) {
                              return 'A note with this name already exists!\nPlease rename your note.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.star),
                            border: OutlineInputBorder(),
                            hintText: 'Enter the name of your note.',
                            isDense: true,
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                            controller: noteBodyController,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter a body for your note.';
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
                        notesBox.put(
                            noteTitleController.text, noteBodyController.text);
                        print(noteTitleController.text);
                        if (widget.note != null &&
                            noteTitleController.text !=
                                widget.note.title.toString()) {
                          notesBox.delete(widget.note.title.toString());
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyApp(),
                          ),
                        );
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
            )))));
  }
}
