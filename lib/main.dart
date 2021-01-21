import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share/share.dart';
import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';
import 'dart:io' show Platform;

import 'data/hive_database.dart';
import 'camera.dart';

const String notesBoxName = "notesBox";

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>(notesBoxName);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TC\'s Notes',
    initialRoute: '/notes',
    routes: {
      '/notes': (context) => NotesApp(),
      '/notes/add': (context) => NoteForm(),
      '/notes/edit': (context) => NoteForm(),
      '/notes/view': (context) => ViewNote(),
      '/camera': (context) => CameraWidget(),
    },
  ));
}

class NotesApp extends StatefulWidget {
  @override
  _NotesAppState createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TC\'s Notes'),
      ),
      body: Center(
        child: ValueListenableBuilder(
            valueListenable: Hive.box<Note>(notesBoxName).listenable(),
            builder: (context, Box<Note> box, _) {
              if (box.isEmpty)
                return Center(
                  child: Text(
                      "No notes saved.\nTap the floating button to add one!"),
                );
              return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    Note note = box.getAt(index);
                    var previewText = note.body;
                    if (previewText.length > 25) {
                      previewText = previewText.replaceRange(
                          25, previewText.length, '...');
                    }
                    return Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Text(previewText),
                        leading: Icon(Icons.note, size: 56),
                        onTap: () {
                          Navigator.pushNamed(context, '/notes/view',
                              arguments: [note, index]);
                        },
                      ),
                      actions: [
                        IconSlideAction(
                          caption: 'Share',
                          color: Colors.yellow,
                          icon: Icons.share,
                          onTap: () {
                            if (Platform.isAndroid || Platform.isIOS) {
                              if (note.imageLocation != null &&
                                  note.imageLocation != '') {
                                Share.shareFiles([note.imageLocation],
                                    text: note.title + '\n' + note.body,
                                    subject: note.title);
                              } else {
                                Share.share(note.title + '\n' + note.body,
                                    subject: note.title);
                              }
                            } else {
                              Clipboard.setData(ClipboardData(
                                  text: note.title + '\n' + note.body));
                              final snackBar = SnackBar(
                                content: Text('Note copied to clipboard'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: ''));
                                  },
                                ),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                        )
                      ],
                      secondaryActions: [
                        IconSlideAction(
                            caption: 'Edit',
                            color: Colors.blue,
                            icon: Icons.edit,
                            onTap: () {
                              print('editing list tile');
                              Navigator.pushNamed(context, '/notes/edit',
                                  arguments: [note, index, true]);
                            }),
                        IconSlideAction(
                            caption: 'Delete',
                            color: Colors.red,
                            icon: Icons.delete,
                            onTap: () {
                              print('deleting list tile');
                              box.delete(box.keyAt(index));
                              Navigator.pushNamed(context, '/notes');
                            }),
                      ],
                    );
                  });
            }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/notes/add');
        },
        tooltip: 'Add Note',
        label: Text('New Note'),
        icon: Icon(Icons.note_add),
      ),
    );
  }
}

class ViewNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List args = ModalRoute.of(context).settings.arguments;
    Note note;
    int noteIndex;
    if (args != null) {
      note = args[0];
      noteIndex = args[1];
    }

    void handleClick(String value) {
      switch (value) {
        case 'Edit':
          Navigator.pushNamed(context, "/notes/edit",
              arguments: [note, noteIndex, true]);
          break;
        case 'Delete':
          print('deleting list tile');
          Box<Note> notesBox = Hive.box<Note>(notesBoxName);
          notesBox.deleteAt(noteIndex);
          Navigator.pop(context);
          Navigator.pushNamed(context, '/notes');
          break;
        case 'Share':
          if (Platform.isAndroid || Platform.isIOS) {
            if (note.imageLocation != null && note.imageLocation != '') {
              Share.shareFiles([note.imageLocation],
                  text: note.title + '\n' + note.body, subject: note.title);
            } else {
              Share.share(note.title + '\n' + note.body, subject: note.title);
            }
          } else {
            Clipboard.setData(
                ClipboardData(text: note.title + '\n' + note.body));
            final snackBar = SnackBar(
              content: Text('Note copied to clipboard'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ''));
                },
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(note.title),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: handleClick,
              itemBuilder: (BuildContext context) {
                return {'Edit', 'Delete', 'Share'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Center(
                child: Column(children: [
          note.imageLocation == null ||
                  note.imageLocation == '' ||
                  Platform.isWindows ||
                  Platform.isFuchsia ||
                  Platform.isMacOS
              ? SizedBox()
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Image.file(
                    Platform.isWindows || Platform.isFuchsia || Platform.isMacOS
                        ? ''
                        : File(note.imageLocation),
                    height: 500,
                  )),
          Padding(padding: EdgeInsets.all(15.0), child: Text(note.body)),
        ]))));
  }
}

// Add Note Form Widget
class NoteForm extends StatefulWidget {
  @override
  ChangeNote createState() {
    return ChangeNote();
  }
}

class ChangeNote extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  var noteTitleController = TextEditingController();
  var noteBodyController = TextEditingController();
  var noteImageLocation = TextEditingController();
  Box<Note> notesBox = Hive.box<Note>(notesBoxName);
  var pageTitle = Text("New Note");
  bool editing = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    noteTitleController.dispose();
    noteBodyController.dispose();
    noteImageLocation.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final List args = ModalRoute.of(context).settings.arguments;
    Note note;
    int noteIndex;

    if (args != null) {
      print('editing ' + args[1].toString());
      note = args[0];
      noteIndex = args[1];
      if (args.length > 2) {
        editing = args[2];
      }
    }

    if (editing) {
      pageTitle = Text("Edit Note");
    }

    if (note != null) {
      noteTitleController = TextEditingController(text: note.title);
      noteBodyController = TextEditingController(text: note.body);
      noteImageLocation = TextEditingController(text: note.imageLocation);
    }

    return Scaffold(
        appBar: AppBar(
          title: pageTitle,
        ),
        body: SingleChildScrollView(
            child: Center(
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
                        } else if (note == null &&
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
                    Platform.isWindows || Platform.isFuchsia || Platform.isMacOS
                        ? SizedBox()
                        : RaisedButton(
                            child: Text('Take Picture'),
                            onPressed: () {
                              Navigator.pop(context);
                              if (editing) {
                                Navigator.pushNamed(context, '/camera',
                                    arguments: [
                                      Note(
                                          noteTitleController.text,
                                          noteBodyController.text,
                                          noteImageLocation.text),
                                      noteIndex,
                                      editing
                                    ]);
                              } else {
                                Navigator.pushNamed(context, '/camera',
                                    arguments: [
                                      Note(noteTitleController.text,
                                          noteBodyController.text, null),
                                      noteIndex,
                                      editing
                                    ]);
                              }
                            },
                          )
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              FlatButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    print('saving note with title ' + noteTitleController.text);
                    note = Note(noteTitleController.text,
                        noteBodyController.text, noteImageLocation.text);
                    if (noteIndex != null) {
                      print('overwriting note at ' + noteIndex.toString());
                      try {
                        notesBox.putAt(noteIndex, note);
                      } catch (e) {
                        print('Failed to replace old note. Error: ' + e);
                      }
                    } else {
                      print('saving new note');
                      notesBox.add(note);
                    }
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/notes', (Route<dynamic> route) => false);
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
