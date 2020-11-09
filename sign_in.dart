import 'package:flutter/material.dart';
import 'package:medicalclient/language.dart';
import 'package:medicalclient/main.dart';
import 'sign_up.dart';
import 'darkmode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart' as db;

class SignInPage extends StatefulWidget {
  final MyState parent;
  SignInPage({Key key, this.parent}) : super(key: key);

  static bool keepSignedIn = false;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  SigninState createState() => SigninState();
}

class SigninState extends State<SignInPage> {
  TextEditingController _id = new TextEditingController();
  TextEditingController _password = new TextEditingController();
  bool keepSignedIn = false;

  Future login(BuildContext context) async {
    String id = _id.text.toString();
    String password = _password.text.toString();
    Navigator.push(context, MaterialPageRoute<void>(builder: (context) {
      return AlertDialog(
        title: SizedBox(
            height: 300.0,
            width: 300.0,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue),
                strokeWidth: 5.0)),
      );
    }));

    bool found = false;
    for (var i in db.clientsNames) {
      var users = db.clients[i]['Users'];
      if (users != null && users.containsKey(id) && users[id] == password) {
        found = true;
        db.company = i;
        db.distributor = db.clients[db.company]['Distributor']['Distributor'];
        print(db.company + " " + db.clients[db.company].toString());
        break;
      }
    }
    Navigator.pop(context);
    if (found) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Language.of(context).getTrans("Login Successful")),
          actions: [
            FlatButton(
              child: Text(Language.of(context).getTrans('Okay')),
              onPressed: () {
                widget.parent.signedIn = true;
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (context) => widget.parent.build(context),
                ));
              },
            )
          ],
        ),
      );
      if (keepSignedIn) {
        SharedPreferences prefs = (await SharedPreferences.getInstance());
        prefs.setString('ID', id);
        prefs.setString('Password', password);
        prefs.setString('Company', db.company);
        prefs.setBool('Distributor', db.distributor);
      }
    } else {
      Navigator.push(context, MaterialPageRoute<void>(builder: (context) {
        return AlertDialog(
          title: Text(
              Language.of(context).getTrans("Incorrect Username or Password")),
          actions: [
            FlatButton(
              child: Text(Language.of(context).getTrans('Okay')),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      }));
    }
  }

  void signUp(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return SignUp(
        parent: widget.parent,
      );
    }));
  }

  Future saveLang(bool arabic) async {
    SharedPreferences prefs = (await SharedPreferences.getInstance());
    prefs.setBool("Lang", arabic);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(Language.of(context).getTrans('Welcome')),
        //Pop Up Menu for Dark Mode / Language
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (value) {
              switch (value) {
                case 1:
                  setState(() {
                    widget.parent.changeTheme();
                  });
                  break;
                case 2:
                  Locale temp;
                  if (db.arabic) {
                    temp = Locale("en", "US");
                    db.arabic = false;
                  } else {
                    temp = Locale("ar", "EG");
                    db.arabic = true;
                  }
                  saveLang(db.arabic);
                  widget.parent.setLocale(temp);
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<int>(
                  value: 1,
                  child: (DarkMode.value
                      ? Text(Language.of(context).getTrans('Disable Dark Mode'))
                      : Text(
                          Language.of(context).getTrans('Enable Dark Mode'))),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Text(Language.of(context).getTrans('Lang')),
                ),
              ];
            },
          )
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset('images/logo.jpg')),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32.2),
                child: Row(
                  children: <Widget>[
                    Text(Language.of(context).getTrans('ID:')),
                    Container(
                      width: 200,
                      height: 75,
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: TextField(
                        controller: _id,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(Language.of(context).getTrans('Password:')),
                    Container(
                      width: 200,
                      height: 75,
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: TextField(
                        controller: _password,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 62.2),
                child: CheckboxListTile(
                  value: keepSignedIn,
                  onChanged: (value) {
                    setState(() {
                      keepSignedIn = value;
                    });
                  },
                  title:
                      Text(Language.of(context).getTrans('Keep Me Signed in')),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              RaisedButton(
                child: Text(
                  Language.of(context).getTrans('Login'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => login(context),
                color: Colors.blue,
              ),
              FlatButton(
                child: Text(
                  Language.of(context).getTrans('Sign Up'),
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => signUp(context),
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
