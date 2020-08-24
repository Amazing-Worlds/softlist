// Copyright 2020 Amazing Worlds. All rights reserved.
/*
TODO:
  1. Storage data
  - save/load list to firebase if user is authanticated by firebase
  - save/load list to SharedPreferences if user is no authanticated
  2. show login help about anonynous w/o registration, 
     need to implement anonymous login button in the flutter login page
  3. show user info: email, add logout button
  0. check for auth before login screen . stete should be persisting 
  not need to auth again 
  4. add settings: separate page, name, reset all data
  5. delete all user data
*/

import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

//firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// internal modules
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  List<String> _items = [];
  List<bool> _selectedLT = [];
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    // TODO: what is no connection???

    if (auth.currentUser.isAnonymous == true) {
      SharedPreferences _prefs = await SharedPreferences.getInstance();

      _items = _prefs.getStringList('FirstListNames');
      List<String> _itemsBoolString = _prefs.getStringList('FirstListBool');
      _selectedLT = List.generate(
          _items.length, (i) => _itemsBoolString[i] == "true" ? true : false);
    } else {
      // load from firestore
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      //print('loadList userID:' + auth.currentUser.uid);
      DocumentSnapshot snapShot = await users.doc(auth.currentUser.uid).get();

      Map<String, dynamic> data = snapShot.data();
      if (data == null) {
        print('Data was NOT loaded');
        //setState(() {});
        return;
      }

      if (data.containsKey('FirstListNames') == true) {
        _items = List<String>.from(jsonDecode(data['FirstListNames'])).toList();
      }
      if (data.containsKey('FirstListBool') == true) {
        _selectedLT =
            List<bool>.from(jsonDecode(data['FirstListBool'])).toList();
      }
    }

    setState(() {});
  }

  void _saveList() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    if (auth.currentUser.isAnonymous == true) {
      // local save
      SharedPreferences _prefs = await SharedPreferences.getInstance();

      _prefs.setStringList('FirstListNames', _items);
      _prefs.setStringList('FirstListBool',
          List.generate(_items.length, (i) => _selectedLT[i].toString()));
    } else {
      // save document into firestore

      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // check existing of document if no create it
      DocumentSnapshot ref = await users.doc(auth.currentUser.uid).get();
      if (ref.exists == false) {
        users.doc(auth.currentUser.uid).set({
          'userID': auth.currentUser.uid,
          'FirstListNames': jsonEncode(_items),
          'FirstListBool': jsonEncode(_selectedLT)
        }).catchError((onError) => print('Failed to add doc: $onError'));
      } else {
        users.doc(auth.currentUser.uid).update({
          'FirstListNames': jsonEncode(_items),
          'FirstListBool': jsonEncode(_selectedLT)
        }).catchError((onError) => print('Failed to update doc: $onError'));
      }
    }
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
          itemCount: _items.length,
        ),
      ),
      TextField(
        //CupertinoTextField(
        //clearButtonMode: OverlayVisibilityMode.always,
        onSubmitted: (text) {
          setState(() {
            _items.add(text);
            _selectedLT.add(false);
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

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return Dismissible(
        confirmDismiss: (direction) => _confirmDismiss(direction),
        onDismissed: (direction) {
          setState(() {
            _items.removeAt(index);
            _selectedLT.removeAt(index);
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
