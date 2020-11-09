import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medicalclient/language.dart';
import 'sign_in.dart';
import 'home_page.dart';
import 'darkmode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'waiting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart' as db;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  MyState createState() => MyState();
}

class MyState extends State<MyApp> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool done = false, signedIn;
  Locale _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void changeTheme() {
    setState(() {
      DarkMode.value = DarkMode.value ? false : true;
    });
  }

  Future getData() async {
    await Firebase.initializeApp();
    var document = await FirebaseFirestore.instance
        .collection('clients')
        .doc('Company')
        .get();
    db.clientsNames = document.data()['Names'];
    db.ref = document.reference;
    for (String element in db.clientsNames) {
      var a = (await document.reference.collection(element).get()).docs;
      var data = {};
      a.forEach((elemen) {
        data[elemen.id] = elemen.data();
      });
      db.clients[element] = data;
    }
    document = await FirebaseFirestore.instance
        .collection('eva')
        .doc("Medicines")
        .get();
    db.medicines = document.data();
    document = await FirebaseFirestore.instance
        .collection('eva')
        .doc("Category")
        .get();
    db.categories = document.data();
  }

  Future checkdata() async {
    final SharedPreferences prefs = await _prefs;
    if (prefs.containsKey("Lang")) {
      db.arabic = prefs.get("Lang");
      if (db.arabic) {
        _locale = Locale("ar", "EG");
      } else {
        _locale = Locale("en", "US");
      }
    } else {
      db.arabic = false;
      _locale = Locale("en", "US");
    }
    if (prefs.containsKey("ID") && prefs.containsKey("Password")) {
      db.company = prefs.get('Company');
      db.distributor = prefs.get('Distributor');
      signedIn = true;
    } else {
      signedIn = false;
    }
  }

  Future autoSignUp() async {
    if (!done) {
      await getData();
      await checkdata();
      setState(() {
        done = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    autoSignUp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        Language.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('ar', 'EG'),
      ],
      localeResolutionCallback: (locales, supportedLocales) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == locales.languageCode &&
              locale.countryCode == locales.countryCode) {
            return locales;
          }
        }
        return supportedLocales.first;
      },
      locale: _locale,
      title: 'Flutter Demo',
      theme: DarkMode.value ? ThemeData.dark() : ThemeData.light(),
      home: !done
          ? Waiting()
          : this.signedIn
              ? MyHomePage(parent: this)
              : SignInPage(parent: this),
    );
  }
}
