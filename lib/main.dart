// Copyright 2020 Amazing Worlds. All rights reserved.
/*
TODO:
  3. show login help about anonynous w/o registration
  4. Storage data
  - save/load list to firebase if user is authanticated by firebase
  - save/load list to SharedPreferences if user is no authanticated
  1. show user info: email, add logout button
  5. add settings: separate page, name, reset all data
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

void main() {
  runApp(SoftList());
}

class SoftList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //return CupertinoApp(
      title: 'Task List',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.orange,
        cursorColor: Colors.orange,
        textTheme: TextTheme(
          button: TextStyle(
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      home: LoginScreen(MyTaskList()),
    );
  }
}

class MyTaskList extends StatefulWidget {
  @override
  _MyTaskListState createState() => _MyTaskListState();
}

class _MyTaskListState extends State<MyTaskList> {
  static int _itemCount = 0;
  List<String> _items = [];
  List<bool> _selectedLT = [];
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  _loadList() async {
    //SharedPreferences preferences = await SharedPreferences.getInstance();
    //preferences.clear();

    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _itemCount = _prefs.getInt('FirstListLength') ?? 0;
    if (_itemCount == 0) {
      _items = [];
      _selectedLT = [];
      return;
    }

    _items = _prefs.getStringList('FirstListNames');
    List<String> _itemsBoolString = _prefs.getStringList('FirstListBool');
    _selectedLT = List.generate(
        _itemCount, (i) => _itemsBoolString[i] == "true" ? true : false);

    setState(() {});
  }

  _saveList() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setInt('FirstListLength', _itemCount);
    if (_itemCount == 0) return;

    _prefs.setStringList('FirstListNames', _items);
    _prefs.setStringList('FirstListBool',
        List.generate(_itemCount, (i) => _selectedLT[i].toString()));

    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My First List'),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Text(''),
      ),
      body: _buildSuggestions(),
    );

/*
    return CupertinoPageScaffold(
      child: _buildSuggestions(),
    );
  */
  }

  Widget _buildSuggestions() {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.all(14.0),
          itemBuilder: (ctx, index) => _buildListItem(ctx, index),
          separatorBuilder: (_, index) => Divider(),
          itemCount: _itemCount,
        ),
      ),
      TextField(
        //CupertinoTextField(
        //clearButtonMode: OverlayVisibilityMode.always,
        onSubmitted: (text) {
          setState(() {
            _items.add(text);
            _selectedLT.add(false);
            _itemCount++;
            _nameController.clear();
            _saveList();
          });
        },
        controller: _nameController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'New list item',
        ),
      )
    ]);
  }

  Widget _buildListItem(BuildContext ctx, int index) {
    final _item = _items[index];

    Future<bool> _confirmDismiss(DismissDirection direction) async {
      if (direction == DismissDirection.startToEnd) {
        return true;
      } else {
        setState(() => _selectedLT[index] = !_selectedLT[index]);
        return false;
      }
    }

    return Dismissible(
        confirmDismiss: (direction) => _confirmDismiss(direction),
        onDismissed: (direction) {
          setState(() {
            _items.removeAt(index);
            _selectedLT.removeAt(index);
            _itemCount--;
            _saveList();
          });
        },
        background: Container(
          color: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: AlignmentDirectional.centerStart,
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        secondaryBackground: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          color: Colors.green,
          alignment: Alignment.centerRight,
          child: Icon(Icons.check),
        ),
        key: ValueKey(_item),
        child: ListTile(
            leading: _selectedLT[index] == true
                ? Icon(Icons.check, color: Colors.green)
                : Icon(Icons.check_box_outline_blank),
            title: Text(_item,
                style: TextStyle(
                    decoration: _selectedLT[index] == true
                        ? TextDecoration.lineThrough
                        : null,
                    fontSize: 14.0)),
            onTap: () => setState(() {
                  _selectedLT[index] = !_selectedLT[index];
                  _saveList();
                })));
  }
}
