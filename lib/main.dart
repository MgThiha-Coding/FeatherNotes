import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(home: Feather()));

class Feather extends StatefulWidget {
  const Feather({super.key});

  @override
  State<Feather> createState() => _FeatherState();
}

class _FeatherState extends State<Feather> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, String>> _notes = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stringNote = prefs.getString('Notes');
    if (stringNote != null) {
      List<dynamic> dynamicList = jsonDecode(stringNote);
      setState(() {
        _notes = dynamicList.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String stringNote = jsonEncode(_notes);
    await prefs.setString('Notes', stringNote);
    _showSnackbar('Note saved successfully!');
  }

  void _addNote() {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      setState(() {
        _notes.add({
          'title': _titleController.text,
          'content': _contentController.text
        });
      });
      _titleController.clear();
      _contentController.clear();
      _saveNotes();
    }
  }

  void _deleteNoteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(index);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
      _saveNotes();
    });
    _showSnackbar('Note deleted successfully!');
  }

  void _editNoteFullScreen(int index) {
    _titleController.text = _notes[index]['title']!;
    _contentController.text = _notes[index]['content']!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Edit Note'),
            actions: [
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () {
                  setState(() {
                    _notes[index] = {
                      'title': _titleController.text,
                      'content': _contentController.text
                    };
                  });
                  _titleController.clear();
                  _contentController.clear();
                  _saveNotes();
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: 'Content'),
                  maxLines: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feather"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Note'),
            Tab(text: 'Notes List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Note Tab
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Your Story',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          // Notes List Tab
          ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_notes[index]['title'] ?? ''),
                subtitle: Text(_notes[index]['content'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editNoteFullScreen(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNoteConfirmation(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.save),
      ),
    );
  }
}
