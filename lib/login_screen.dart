// Copyright 2020 Amazing Worlds. All rights reserved.

import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_login/flutter_login.dart';

class MyRegex {
  // https://stackoverflow.com/a/32686261/9449426
  static final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
}

class LoginScreen extends StatelessWidget {
  StatefulWidget _mainScreen;

  LoginScreen(StatefulWidget widget) {
    _mainScreen = widget;
  }

  Duration get loginTime => Duration(milliseconds: 750); // 2250

  Future<String> _authUser(LoginData data) async {
    print('Name: ${data.name}');
    return Future.delayed(loginTime).then((_) async {
      if (data.name.length == 0 && data.password.length == 0) {
/*
        await SharedPreferences.getInstance()
            .then((value) => value.setBool('IsAnonymLogged', true));
        // anonymous login w/o interaction with firebase

        UserCredential _authRes;
        try {
          _authRes = await FirebaseAuth.instance.signInAnonymously();
        } catch (error) {
          if (error is! FirebaseAuthException) {
            return 'Unknown error';
          }
          switch (error.code) {
            case 'operation-not-allowed':
              return "Anonymous access doesn't allow.";
          }
        }
*/
        return null;
      } else {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: data.name, password: data.password);
          return null;
        } catch (error) {
          if (error is! FirebaseAuthException) {
            return 'Unknown error';
          }
          switch (error.code) {
            case 'invalid-email':
              return 'The email address is not valid';
            case 'user-disabled':
              return "The user corresponding to the given email has been disabled.";
            case 'user-not-found':
              return "There is no user corresponding to the given email.";
            case 'wrong-password':
              return "The password is invalid for the given email, or the account.";
            default:
              return error.toString();
          }
        }
      }
      //return 'Unknown error';
    });
  }

  Future<UserCredential> signUpWithEmail(LoginData data) async {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data.name, password: data.password);
  }

  Future<String> _registerUser(LoginData data) async {
    print('Name: ${data.name}');
    return Future.delayed(loginTime).then((_) async {
      UserCredential _authRes;
      try {
        _authRes = await signUpWithEmail(data);
      } catch (error) {
        if (error is! FirebaseAuthException) {
          return 'Unknown error';
        }
        switch (error.code) {
          case 'email-already-in-use':
            return 'The email is already in use by a different account.';
          case 'invalid-email':
            return 'The email address is malformed.';
          case 'weak-password':
            return 'The password is not strong enough.';
        }
      }
      // create document about user in the firestore
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      print(_authRes.user.uid);
      users
          .doc(_authRes.user.uid)
          .set({'userID': _authRes.user.uid}).catchError(
              (error) => print("Failed to add user: $error"));

      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    print('Name: $name');
    return Future.delayed(loginTime).then((_) async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: name);
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'invalid-email':
            return 'The email address is malformed.';
          case 'user-not-found':
            return 'There is no user corresponding to the given email address.';
        }
      }
      return null;
    });
  }

  static final FormFieldValidator<String> emailValidator = (value) {
    if (value.length == 0) {
      return null;
    }
    if (!MyRegex.email.hasMatch(value)) {
      return 'Invalid email!';
    }
    return null;
  };

  static final FormFieldValidator<String> passValidator = (value) {
    if (value.length == 0) {
      return null;
    }
    if (value.length < 6) {
      return 'Password must be more than 6 symbols';
    }
    return null;
  };

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return _mainScreen;
    }
/*
    return FutureBuilder<bool>(
        future: SharedPreferences.getInstance()
            .then((value) => value.getBool('IsAnonymLogged')),
        builder: (BuildContext context, AsyncSnapshot<bool> isAnonymLogged) {
          if (FirebaseAuth.instance.currentUser != null) {
            SharedPreferences.getInstance()
                .then((value) => value.setBool('IsAnonymLogged', false));
            return _mainScreen;
          }

          if (isAnonymLogged.hasData == true) if (isAnonymLogged.data == true) {
            return _mainScreen;
          }

          return FlutterLogin(
            // ADD PROPER MESSAGES ABOUT ANONYMOUS LOGINS
            title: 'Softlist',
            //logo: 'images/Icon-App-83.5x83.5@2x.png',
            onLogin: _authUser,
            onSignup: _registerUser,
            emailValidator: emailValidator,
            passwordValidator: passValidator,
            onSubmitAnimationCompleted: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => _mainScreen,
              ));
            },
            onRecoverPassword: _recoverPassword,
          );
        });*/
    return FlutterLogin(
      // ADD PROPER MESSAGES ABOUT ANONYMOUS LOGINS
      title: 'Softlist',
      //logo: 'images/Icon-App-83.5x83.5@2x.png',
      onLogin: _authUser,
      onSignup: _registerUser,
      emailValidator: emailValidator,
      passwordValidator: passValidator,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => _mainScreen,
        ));
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
