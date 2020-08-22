// Copyright 2020 Amazing Worlds. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Duration get loginTime => Duration(milliseconds: 750); // 2250

  Future<String> _authUser(LoginData data) async {
    print('Name: ${data.name}');
    return Future.delayed(loginTime).then((_) async {
      if (data.name.length == 0 && data.password.length == 0) {
        AuthResult _authRes;
        try {
          _authRes = await _auth.signInAnonymously();
        } catch (error) {
          if (error is! PlatformException) {
            return 'Unknown error';
          }
          switch (error.code) {
            case 'ERROR_OPERATION_NOT_ALLOWED':
              return "Anonymous access doesn't allow.";
          }
        }
        return null;
      } else {
        AuthResult _authRes;
        try {
          _authRes = await _auth.signInWithEmailAndPassword(
              email: data.name, password: data.password);
        } catch (error) {
          if (error is! PlatformException) {
            return 'Unknown error';
          }
          switch (error.code) {
            // add more error cases
            case 'ERROR_USER_NOT_FOUND':
              return "No any user corresponding to the given email address.";
            case 'ERROR_WRONG_PASSWORD':
              return "The password is wrong.";
            case 'ERROR_TOO_MANY_REQUESTS':
              return "There was too many attempts to sign in as this user.";
          }
        }
      }
      return null;
    });
  }

  Future<AuthResult> signUpWithEmail(LoginData data) async {
    return _auth.createUserWithEmailAndPassword(
        email: data.name, password: data.password);
  }

  Future<String> _registerUser(LoginData data) async {
    print('Name: ${data.name}');
    return Future.delayed(loginTime).then((_) async {
      AuthResult _authRes;
      try {
        _authRes = await signUpWithEmail(data);
      } catch (error) {
        if (error is! PlatformException) {
          return 'Unknown error';
        }
        switch (error.code) {
          case 'ERROR_WEAK_PASSWORD':
            return 'The password is not strong enough.';
          case 'ERROR_INVALID_EMAIL':
            return 'The email address is malformed.';
          case 'ERROR_EMAIL_ALREADY_IN_USE':
            return 'The email is already in use by a different account.';
        }
      }
      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    print('Name: $name');
    return Future.delayed(loginTime).then((_) async {
      try {
        await _auth.sendPasswordResetEmail(email: name);
      } on PlatformException catch (e) {
        switch (e.code) {
          case 'ERROR_INVALID_EMAIL':
            return 'The email address is malformed.';
          case 'ERROR_INVALID_EMAIL':
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
