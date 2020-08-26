// Copyright 2020 Amazing Worlds. All rights reserved.
/*
TODO:
  0. Open Drawer from icon
  0.1 show email of the user if it was logged or anonym if not
  1. add logout button
  1.5 comment opening multy task list page
  2. check for auth before login screen . stete should be persisting
  not need to auth again if user has already entered password before
  3. show login help about anonynous w/o registration,
     need to implement anonymous login button in the flutter login page
  4. show user email (before @)
  4. user settigns info: separate page, email, change password
  6. delete all user data
  7. multy lists for money - add/remove lists

  stage 2:
    Perfomance optimization
    Cupertino specific design and make it mixed with Material, test on Android
    https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple
    https://pub.dev/packages/provider
    https://codelabs.developers.google.com/codelabs/first-flutter-app-pt2/#5
*/

//import 'package:flutter/cupertino.dart';
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

    if (auth.currentUser == null) {
      // anonym user
      SharedPreferences _prefs = await SharedPreferences.getInstance();

      _items = _prefs.getStringList('FirstListNames');
      List<String> _itemsBoolString = _prefs.getStringList('FirstListBool');
      _selectedLT = List.generate(
          _items.length, (i) => _itemsBoolString[i] == "true" ? true : false);
    } else {
      // load from firestore
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      DocumentSnapshot snapShot = await users.doc(auth.currentUser.uid).get();

      Map<String, dynamic> data = snapShot.data();
      if (data == null) {
        print('Data was not loaded');
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

    //if (auth.currentUser.isAnonymous == true) {
    if (auth.currentUser == null) {
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

/*
  void settingsPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
            child: Column(children: [
          AppBar(
            title: const Text('Next page'),
          ),
          const Center(
            child: Text(
              'This is the next page',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ]));
      },
    ));
  }
*/
  Widget createDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          AppBar(
              title: Text('Profile'),
              leading: IconButton(
                icon: const Icon(Icons.settings_cell),
                tooltip: 'Profile',
                onPressed: () {
                  //settingsPage(context);
                  //Scaffold.of(context).openDrawer();
                },
              )),
          ListTile(
            leading: Icon(Icons.message),
            title: Text('Messages'),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Log out'),
            onTap: () {
              // Close Drawer
              Navigator.pop(context);
              // return to login screen
            },
          ),
        ],
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: createDrawer(context),
      appBar: AppBar(
          title: Text('My First List'),
          /*actions: <Widget>[const Icon(Icons.settings),
            tooltip: 'Profile',
            onPressed: () {
              // Open Drawer
              //settingsPage(context);
              //Scaffold.of(context).openDrawer();
            },],*/
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Profile',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          )),
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

  void _loadListFromSnap(AsyncSnapshot<DocumentSnapshot> snapshot) {
    // load document from firestore
    if (snapshot.hasData == false) {
      return;
    }

    Map<String, dynamic> data = snapshot.data.data();
    if (data == null) {
      return;
    }

    if (data.containsKey('FirstListNames') == true) {
      _items = List<String>.from(jsonDecode(data['FirstListNames'])).toList();
    }
    if (data.containsKey('FirstListBool') == true) {
      _selectedLT = List<bool>.from(jsonDecode(data['FirstListBool'])).toList();
    }
  }

  Widget _createColumn() {
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

  Widget _buildSuggestions() {
    FirebaseAuth auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      return _createColumn();
    }

    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid);

    return StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            print("Error occured");
            return Text("Error occured");
          }

          if (snapshot.connectionState != ConnectionState.waiting) {
            _loadListFromSnap(snapshot);
          }
          return _createColumn();
        });
  }

  Widget _buildListItem(BuildContext ctx, int index) {
    var _item = _items[index];

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
            if (_items.contains(_item)) {
              _items.removeAt(index);
              _selectedLT.removeAt(index);
            }
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
        key: UniqueKey(),
        dismissThresholds: {
          DismissDirection.startToEnd: 0.35,
          DismissDirection.endToStart: 0.35
        },
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
