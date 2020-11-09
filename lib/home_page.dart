import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medicalclient/language.dart';
import 'package:medicalclient/main.dart';
import 'package:medicalclient/waiting.dart';
import 'new_request.dart';
import 'darkmode.dart';
import 'request_data.dart';
import 'offer_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart' as db;

class MyHomePage extends StatefulWidget {
  final MyState parent;
  MyHomePage({Key key, bool distributor, this.parent}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final PageController controller = PageController(
    initialPage: 0,
  );
  static int pageIndex = 0;
  static List<RequestData> requests = List();

  @override
  void initState() {
    super.initState();
    pageIndex = 0;
  }

  void newRequest(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return NewRequest();
    }));
  }

  Future logOut() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("ID") && prefs.containsKey("Password")) {
      prefs.remove("ID");
      prefs.remove("Password");
      prefs.remove('Company');
      prefs.remove('Distributor');
    }
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
      appBar: new AppBar(
        title: new Text(Language.of(context).getTrans("Home")),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (value) {
              switch (value) {
                case 1:
                  setState(() {
                    widget.parent.changeTheme();
                  });
                  break;
                case 3:
                  logOut();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text(Language.of(context)
                            .getTrans('Log Out Successful')),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(
                              Language.of(context).getTrans('Okay'),
                              style: TextStyle(color: Colors.blue),
                            ),
                            onPressed: () {
                              widget.parent.signedIn = false;
                              Navigator.pop(context);
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                      builder: (context) =>
                                          widget.parent.build(context)));
                            },
                          )
                        ],
                      );
                    },
                  );
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
                PopupMenuItem<int>(
                  value: 3,
                  child: Text(Language.of(context).getTrans('Log Out')),
                ),
              ];
            },
          )
        ],
      ),
      body: PageView(
        controller: controller,
        onPageChanged: (value) {
          setState(() {
            pageIndex = value;
          });
        },
        children: (db.distributor)
            ? <Widget>[
                _Requests(),
                _SentRequests(),
                _Offers(),
              ]
            : <Widget>[
                _Requests(),
                _Offers(),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => newRequest(context),
      ),
      floatingActionButtonLocation: db.distributor
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
            controller.jumpToPage(index);
          });
        },
        items: db.distributor
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.call_made),
                  title: Text(Language.of(context).getTrans('Sent')),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.call_received),
                  title: Text(Language.of(context).getTrans('Received')),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard),
                  title: Text(Language.of(context).getTrans('Offers')),
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.create_new_folder),
                  title: Text(Language.of(context).getTrans('Requests')),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard),
                  title: Text(Language.of(context).getTrans('Offers')),
                ),
              ],
      ),
    );
  }
}

class _Requests extends StatefulWidget {
  @override
  _RequestsState createState() => new _RequestsState();
}

class _RequestsState extends State<_Requests> {
  List<RequestData> _requests = [];

  Future delete({RequestData data}) {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentReference cRef =
          db.ref.collection(db.company).doc("Sent Requests");
      DocumentReference sRef =
          db.ref.collection(data.dist).doc("Received Requests");
      DocumentSnapshot client = await transaction.get(cRef),
          server = await transaction.get(sRef);
      Map sentRequests = client.data();
      for (var i = 0; i < sentRequests[data.dist].length; i++) {
        if (sentRequests[data.dist][i].keys.toList()[0] == data.timeStamp) {
          sentRequests[data.dist].removeAt(i);
          break;
        }
      }
      if (sentRequests[data.dist].isEmpty)
        sentRequests[data.dist] = FieldValue.delete();
      transaction.update(cRef, sentRequests);
      sentRequests = server.data();
      for (var i = 0; i < sentRequests[db.company].length; i++) {
        if (sentRequests[db.company][i].keys.toList()[0] == data.timeStamp) {
          sentRequests[db.company].removeAt(i);
          break;
        }
      }
      if (sentRequests[db.company].isEmpty)
        sentRequests[db.company] = FieldValue.delete();
      transaction.update(sRef, sentRequests);
    });
  }

  Widget requestDelete(BuildContext context, {RequestData data}) {
    return AlertDialog(
      content: Text(Language.of(context).getTrans('DelMes')),
      actions: <Widget>[
        FlatButton(
          child: Text(
            Language.of(context).getTrans('Yes'),
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () async {
            await delete(data: data).then((value) => Navigator.pop(context));
          },
        ),
        FlatButton(
          child: Text(
            Language.of(context).getTrans('No'),
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  void requestSelect(BuildContext context, {RequestData data, int index}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(data.name +
            ":\n" +
            Language.of(context).getTrans('Distributor: ') +
            data.dist +
            "\n" +
            Language.of(context).getTrans("Quantity: ") +
            data.quantity +
            "\n" +
            Language.of(context).getTrans("Price: ") +
            data.price),
        actions: <Widget>[
          FlatButton(
            child: Text(
              Language.of(context).getTrans('Delete'),
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => requestDelete(context, data: data),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('clients')
            .doc('Company')
            .collection(db.company)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            _requests.clear();
            for (var j in snapshot.data.docs) {
              if (j.id == "Sent Requests") {
                var R = j.data();
                List<Map> temp = [];
                for (var item in R.keys) {
                  for (var inner in R[item]) {
                    temp.add(inner);
                  }
                }
                temp.sort((Map a, Map b) {
                  return a.keys.toList()[0].compareTo(b.keys.toList()[0]);
                });
                for (var i in temp) {
                  if (i.isNotEmpty) {
                    var key = i.keys.toList()[0];
                    _requests.add(RequestData(
                        title: i[key]['Title'],
                        name: i[key]['Medicine'],
                        barcode: i[key]['Barcode'],
                        quantity: i[key]['Quantity'],
                        dist: i[key]['Distributor'],
                        price: i[key]['Price'],
                        timeStamp: key));
                  }
                }
                break;
              }
            }
            return new Container(
              padding: new EdgeInsets.all(32.0),
              child: new Center(
                child: _requests.length == 0
                    ? Container(
                        height: 400,
                        width: 500,
                        child: Opacity(
                            opacity: 0.6,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Image.asset("images/empty.png"),
                                ),
                                Text(
                                  Language.of(context).getTrans("No Requests"),
                                  style: TextStyle(fontSize: 20),
                                )
                              ],
                            )),
                      )
                    : ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (BuildContext context, int i) {
                          return ListTile(
                            onTap: () => requestSelect(context,
                                data: _requests.elementAt(i), index: i),
                            title: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Text(
                                    "${_requests.elementAt(i).dist}, ${_requests.elementAt(i).title}"),
                              ),
                            ),
                          );
                        }),
              ),
            );
          }
          return Waiting();
        });
  }
}

class _SentRequests extends StatefulWidget {
  @override
  __SentRequestsState createState() => __SentRequestsState();
}

class __SentRequestsState extends State<_SentRequests> {
  List<RequestData> _requests = [];

  Future delete({RequestData data}) {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentReference cRef =
          db.ref.collection(db.company).doc("Received Requests");
      DocumentReference sRef =
          db.ref.collection(data.dist).doc("Sent Requests");
      DocumentSnapshot client = await transaction.get(cRef),
          server = await transaction.get(sRef);
      Map sentRequests = client.data();
      for (var i = 0; i < sentRequests[data.dist].length; i++) {
        if (sentRequests[data.dist][i].keys.toList()[0] == data.timeStamp) {
          sentRequests[data.dist].removeAt(i);
          break;
        }
      }
      if (sentRequests[data.dist].isEmpty)
        sentRequests[data.dist] = FieldValue.delete();
      transaction.update(cRef, sentRequests);
      sentRequests = server.data();
      for (var i = 0; i < sentRequests[db.company].length; i++) {
        if (sentRequests[db.company][i].keys.toList()[0] == data.timeStamp) {
          sentRequests[db.company].removeAt(i);
          break;
        }
      }
      if (sentRequests[db.company].isEmpty)
        sentRequests[db.company] = FieldValue.delete();
      transaction.update(sRef, sentRequests);
    });
  }

  Widget requestDelete(BuildContext context, {RequestData data}) {
    return AlertDialog(
      content: Text(Language.of(context).getTrans("RefMes")),
      actions: <Widget>[
        FlatButton(
          child: Text(
            Language.of(context).getTrans('Yes'),
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () async {
            await delete(data: data).then((value) => Navigator.pop(context));
          },
        ),
        FlatButton(
          child: Text(
            Language.of(context).getTrans('No'),
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  Widget requestAccept(BuildContext context, {RequestData data}) {
    return AlertDialog(
      content: Text(Language.of(context).getTrans("AccMes")),
      actions: <Widget>[
        FlatButton(
          child: Text(
            Language.of(context).getTrans('Yes'),
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () async {
            await delete(data: data).then((value) => Navigator.pop(context));
          },
        ),
        FlatButton(
          child: Text(
            Language.of(context).getTrans('No'),
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  Future requestSelect(BuildContext context, {RequestData data}) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(data.name +
            ":\n" +
            Language.of(context).getTrans('Client: ') +
            data.dist +
            "\n" +
            Language.of(context).getTrans("Quantity: ") +
            data.quantity +
            "\n" +
            Language.of(context).getTrans("Price: ") +
            data.price),
        actions: <Widget>[
          FlatButton(
            child: Text(
              Language.of(context).getTrans('Accept'),
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => requestAccept(context, data: data),
              );
            },
          ),
          FlatButton(
            child: Text(
              Language.of(context).getTrans('Refuse'),
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => requestDelete(context, data: data),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('clients')
            .doc('Company')
            .collection(db.company)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            _requests.clear();
            for (var j in snapshot.data.docs) {
              if (j.id == "Received Requests") {
                var R = j.data();
                List<Map> temp = [];
                for (var item in R.keys) {
                  for (var inner in R[item]) {
                    temp.add(inner);
                  }
                }
                temp.sort((Map a, Map b) {
                  return a.keys.toList()[0].compareTo(b.keys.toList()[0]);
                });
                for (var i in temp) {
                  if (i.isNotEmpty) {
                    var key = i.keys.toList()[0];
                    _requests.add(RequestData(
                        title: i[key]['Title'],
                        name: i[key]['Medicine'],
                        barcode: i[key]['Barcode'],
                        quantity: i[key]['Quantity'],
                        dist: i[key]['Distributor'],
                        price: i[key]['Price'],
                        timeStamp: key));
                  }
                }
                break;
              }
            }
            return new Container(
              padding: new EdgeInsets.all(32.0),
              child: new Center(
                child: _requests.length == 0
                    ? Container(
                        height: 500,
                        width: 500,
                        child: Opacity(
                            opacity: 0.6,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Image.asset("images/empty.png"),
                                ),
                                Text(
                                  Language.of(context).getTrans("No Requests"),
                                  style: TextStyle(fontSize: 20),
                                )
                              ],
                            )),
                      )
                    : ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (BuildContext context, int i) {
                          return ListTile(
                            onTap: () => requestSelect(context,
                                data: _requests.elementAt(i)),
                            title: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Text(
                                    "${_requests.elementAt(i).dist}, ${_requests.elementAt(i).title}"),
                              ),
                            ),
                          );
                        }),
              ),
            );
          }
          return Waiting();
        });
  }
}

class _Offers extends StatefulWidget {
  @override
  _OffersState createState() => new _OffersState();
}

class _OffersState extends State<_Offers> {
  List<OfferData> offers = [];

  @override
  void initState() {
    super.initState();
  }

  Future offerSelect(BuildContext context, {OfferData data, int index}) async {
    return showDialog(
      context: context,
      child: AlertDialog(
        content: Text('${data.name}:\n' +
            Language.of(context).getTrans('Get') +
            ' ${data.add} ' +
            Language.of(context).getTrans('Free') +
            ' ${data.add == 1 ? Language.of(context).getTrans('Unit') : Language.of(context).getTrans('Units')} ' +
            Language.of(context).getTrans('for every') +
            ' ${data.base}' +
            Language.of(context).getTrans('Units in your Request') +
            '\n' +
            Language.of(context).getTrans('Up to') +
            ' ${data.upperLimit} ' +
            Language.of(context).getTrans('Units bought')),
        actions: <Widget>[
          FlatButton(
            child: Text(
              Language.of(context).getTrans('Accept'),
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewRequest(
                      data: RequestData(
                        name: data.name,
                        barcode: data.barcode,
                        quantity: data.base.toString(),
                      ),
                    ),
                  ));
            },
          ),
          FlatButton(
            child: Text(
              Language.of(context).getTrans('dismiss'),
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('eva').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            offers.clear();
            for (var j in snapshot.data.docs) {
              if (j.id == "Offers") {
                var R = j.data();
                for (var item in R.keys) {
                  offers.add(OfferData(
                      barcode: R[item]["barcode"],
                      name: item,
                      base: R[item]["base"],
                      add: R[item]["add"],
                      upperLimit: R[item]["limit"],
                      text:
                          "$item: ${R[item]["base"]} + ${R[item]["add"]} // ${R[item]["limit"]}"));
                }
                break;
              }
            }
            return new Container(
              padding: new EdgeInsets.all(32.0),
              child: new Center(
                child: offers.length == 0
                    ? Container(
                        height: 500,
                        width: 500,
                        child: Opacity(
                            opacity: 0.6,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Image.asset("images/empty.png"),
                                ),
                                Text(
                                  Language.of(context).getTrans("No Offers"),
                                  style: TextStyle(fontSize: 20),
                                )
                              ],
                            )),
                      )
                    : ListView.builder(
                        itemCount: offers.length,
                        itemBuilder: (BuildContext context, int i) {
                          return ListTile(
                            onTap: () =>
                                offerSelect(context, data: offers.elementAt(i)),
                            title: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Text(offers.elementAt(i).text),
                              ),
                            ),
                          );
                        }),
              ),
            );
          }
          return Waiting();
        });
  }
}
