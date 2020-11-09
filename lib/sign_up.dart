import 'package:flutter/material.dart';
import 'package:medicalclient/language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'darkmode.dart';
import 'database.dart' as db;
import 'main.dart';

class SignUp extends StatefulWidget {
  SignUp({Key key, this.parent}) : super(key: key);
  final MyState parent;
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  TextEditingController _id = new TextEditingController();
  TextEditingController _password = new TextEditingController();
  TextEditingController _secondPassword = new TextEditingController();
  String option;
  List<DropdownMenuItem> clients = [];
  bool distributor = false;
  bool passMatch = true;

  @override
  void initState() {
    super.initState();
    buildClientList();
  }

  void buildClientList() {
    db.clientsNames.forEach((element) {
      clients.add(DropdownMenuItem(
        value: element.toString(),
        child: Text(element.toString()),
      ));
    });
  }

  Future submit() async {
    if (db.clients[option]['Users'].containsKey(_id.text)) {
      Navigator.push(context, MaterialPageRoute<void>(
        builder: (context) {
          return AlertDialog(
            title: Text(
                Language.of(context).getTrans("Username already exists!!!!")),
            actions: [
              FlatButton(
                child: Text(Language.of(context).getTrans('Okay')),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        },
      ));
      return;
    }
    await db.ref
        .collection(option)
        .doc('Users')
        .update({_id.text.toString(): _password.text.toString()});
    db.clients[option]['Users'] =
        (await db.ref.collection(option).doc('Users').get()).data();
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (context) {
        return AlertDialog(
          title: Text(Language.of(context).getTrans("Sign up Successful")),
          actions: [
            FlatButton(
              child: Text(Language.of(context).getTrans('Okay')),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    ));
  }

  Future saveLang(bool arabic) async {
    SharedPreferences prefs = (await SharedPreferences.getInstance());
    prefs.setBool("Lang", arabic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(Language.of(context).getTrans('Sign Up')),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (value) {
              switch (value) {
                case 1:
                  setState(() {
                    DarkMode.value = DarkMode.value ? false : true;
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
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
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
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0))),
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
                        onChanged: (value) {
                          if (value != _secondPassword.text) {
                            setState(() {
                              passMatch = false;
                            });
                          } else {
                            setState(() {
                              passMatch = true;
                            });
                          }
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0))),
                        controller: _password,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(Language.of(context).getTrans('Re-Enter Password:')),
                    Container(
                      width: 200,
                      height: 75,
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: TextField(
                        decoration: InputDecoration(
                            errorText: !passMatch
                                ? Language.of(context)
                                    .getTrans("Passwords mismatch")
                                : null,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide(
                                    color:
                                        passMatch ? Colors.blue : Colors.red))),
                        onChanged: (value) {
                          if (value != _password.text) {
                            setState(() {
                              passMatch = false;
                            });
                          } else {
                            setState(() {
                              passMatch = true;
                            });
                          }
                        },
                        controller: _secondPassword,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ),
              Text(Language.of(context)
                  .getTrans('Pharmacy or Distributor Name:')),
              Container(
                width: 200,
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: DropdownButton(
                  isExpanded: true,
                  value: option,
                  items: clients,
                  onChanged: (value) {
                    setState(() {
                      option = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RaisedButton(
                      onPressed: submit,
                      color: Colors.blue,
                      child: Text(Language.of(context).getTrans('Submit')),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ]),
    );
  }
}
