import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:medicalclient/language.dart';
import 'darkmode.dart';
import 'waiting.dart';
import 'request_data.dart';
import 'database.dart' as db;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class NewRequest extends StatefulWidget {
  final RequestData data;

  NewRequest({this.data, Key key}) : super(key: key);

  @override
  _NewRequestState createState() => _NewRequestState(data: data);
}

class _NewRequestState extends State<NewRequest> {
  TextEditingController name = TextEditingController();
  TextEditingController barcode = TextEditingController();
  TextEditingController quantity = TextEditingController();
  String price;
  RequestData data;
  List<RequestData> list;
  bool edit;
  String option;
  List<DropdownMenuItem> clients = [];
  List medicines = [];
  bool loading = false;
  Image pic;

  _NewRequestState({this.data}) : super();

  @override
  void initState() {
    super.initState();
    buildClientList();
    if (data == null)
      reset();
    else {
      quantity.text = data.quantity;
      name.text = data.name;
      barcode.text = data.barcode;
      price = (int.parse(quantity.text) * db.medicines[data.barcode]["Pbu"])
          .toString();
      loading = true;
    }
  }

  void buildClientList() {
    db.clientsNames.forEach((element) {
      if (db.clients[element].containsKey('Distributor') &&
          db.clients[element]['Distributor']['Distributor'] &&
          element != db.company)
        clients.add(DropdownMenuItem(
          value: element.toString(),
          child: Text(element.toString()),
        ));
    });
  }

  void reset() {
    price = "0";
    quantity.text = "0";
    name.text = "";
    barcode.text = "";
    option = "";
    edit = false;
    loading = false;
  }

  //add data to firebase function

  Future submit(BuildContext context) async {
    DateTime ref = DateTime.now();

    num p = num.parse(price);
    if (db.medicines[barcode.text]["Price Offer"]) {
      DocumentReference documentReference =
          db.ref.collection(db.company).doc('Next Discount');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(documentReference);

        if (snapshot.exists && snapshot.data()['value'] != 0) {
          num n = snapshot.data()['value'];
          if (p >= n) {
            price = (p - n).toString();
            n = 0;
          } else {
            price = "0";
            n -= p;
          }
          transaction.update(documentReference, {'value': n});
        }
      });
    }

    if (!db.clients[db.company].containsKey('Sent Requests')) {
      await db.ref.collection(db.company).doc("Sent Requests").set({
        "$option": [
          {
            ref.toIso8601String(): {
              'Title': "${name.text}, ${ref.day}-"
                  "${ref.month}-${ref.year}, "
                  "${ref.hour}:${ref.minute}:${ref.second}",
              'Medicine': name.text,
              'Barcode': barcode.text,
              'Quantity': quantity.text,
              'Distributor': option,
              'Price': price.toString()
            }
          }
        ]
      });
    } else if (!db.clients[db.company]['Sent Requests'].containsKey(option)) {
      DocumentSnapshot data =
          await db.ref.collection(db.company).doc("Sent Requests").get();
      Map temp = data.data();
      temp[option] = [
        {
          ref.toIso8601String(): {
            'Title': "${name.text}, ${ref.day}-"
                "${ref.month}-${ref.year}, "
                "${ref.hour}:${ref.minute}:${ref.second}",
            'Medicine': name.text,
            'Barcode': barcode.text,
            'Quantity': quantity.text,
            'Distributor': option,
            'Price': price.toString()
          }
        }
      ];
      await db.ref.collection(db.company).doc("Sent Requests").update(temp);
    } else {
      DocumentSnapshot data =
          await db.ref.collection(db.company).doc("Sent Requests").get();
      Map temp = data.data();
      temp[option].add({
        ref.toIso8601String(): {
          'Title': "${name.text}, ${ref.day}-"
              "${ref.month}-${ref.year}, "
              "${ref.hour}:${ref.minute}:${ref.second}",
          'Medicine': name.text,
          'Barcode': barcode.text,
          'Quantity': quantity.text,
          'Distributor': option,
          'Price': price.toString()
        }
      });
      await db.ref.collection(db.company).doc("Sent Requests").update(temp);
    }
    if (!db.clients[option].containsKey('Received Requests')) {
      await db.ref.collection(option).doc("Received Requests").set({
        db.company: [
          {
            ref.toIso8601String(): {
              'Title': "${name.text}, ${DateTime.now().day}-"
                  "${ref.month}-${ref.year}, "
                  "${ref.hour}:${ref.minute}:${ref.second}",
              'Medicine': name.text,
              'Barcode': barcode.text,
              'Quantity': quantity.text,
              'Distributor': db.company,
              'Price': price.toString()
            }
          }
        ]
      });
    } else if (!db.clients[option]['Received Requests']
        .containsKey(db.company)) {
      DocumentSnapshot data =
          await db.ref.collection(option).doc("Received Requests").get();
      var temp = data.data();
      temp[db.company] = [
        {
          ref.toIso8601String(): {
            'Title': "${name.text}, ${ref.day}-"
                "${ref.month}-${ref.year}, "
                "${ref.hour}:${ref.minute}:${ref.second}",
            'Medicine': name.text,
            'Barcode': barcode.text,
            'Quantity': quantity.text,
            'Distributor': db.company,
            'Price': price.toString()
          }
        }
      ];
      await db.ref.collection(option).doc("Received Requests").update(temp);
    } else {
      DocumentSnapshot data =
          await db.ref.collection(option).doc("Received Requests").get();
      var temp = data.data();

      temp[db.company].add({
        ref.toIso8601String(): {
          'Title': "${name.text}, ${ref.day}-"
              "${ref.month}-${ref.year}, "
              "${ref.hour}:${ref.minute}:${ref.second}",
          'Medicine': name.text,
          'Barcode': barcode.text,
          'Quantity': quantity.text,
          'Distributor': db.company,
          'Price': price.toString()
        }
      });
      await db.ref.collection(option).doc("Received Requests").update(temp);
    }
    String message = Language.of(context).getTrans('Your Request of:') +
        ' \n'
            '${quantity.text} ' +
        Language.of(context).getTrans('Units of') +
        ' ${name.text}\n';
    int q = int.parse(quantity.text);
    if (db.medicines[barcode.text]["Quantity Offer"] &&
        q >= db.medicines[barcode.text]["Base Quantity"]) {
      if (q > db.medicines[barcode.text]['Limit']) {
        q = db.medicines[barcode.text]["Limit"];
      }
      int free = ((q ~/ db.medicines[barcode.text]["Base Quantity"]) *
          db.medicines[barcode.text]["Add Quantity"]) as int;
      message += Language.of(context).getTrans('along with') +
          ' $free ' +
          Language.of(context).getTrans('Free') +
          ' ${free == 1 ? Language.of(context).getTrans("Unit") : Language.of(context).getTrans("Units")}\n';
    }
    message +=
        Language.of(context).getTrans('is Successfully Submitted') + '\n';
    int dis = 0;
    var list = db.categories.keys.toList();
    list.sort();
    bool inCat = false;
    for (var item in list) {
      num cat = int.parse(item);
      num p = num.parse(price);
      if (p < cat) {
        inCat = true;
        if (dis != 0) {
          message += Language.of(context).getTrans('also') +
              ', ' +
              Language.of(context).getTrans('You get a') +
              ' ${p * db.categories[dis.toString()]} ' +
              Language.of(context).getTrans('L.E') +
              ' ' +
              Language.of(context)
                  .getTrans('discount on the next request of Selected Items');
          if (!db.clients[db.company].containsKey('Next Discount')) {
            await db.ref
                .collection(db.company)
                .doc("Next Discount")
                .set({"value": p * db.categories[dis.toString()]});
          } else {
            DocumentReference documentReference =
                db.ref.collection(db.company).doc('Next Discount');
            FirebaseFirestore.instance.runTransaction((transaction) async {
              DocumentSnapshot snapshot =
                  await transaction.get(documentReference);
              num newFollowerCount =
                  snapshot.data()['value'] + p * db.categories[dis.toString()];
              transaction
                  .update(documentReference, {'value': newFollowerCount});
            });
          }
        }
        break;
      }
      dis = cat;
    }
    if (!inCat) {
      message += Language.of(context).getTrans('also') +
          ', ' +
          Language.of(context).getTrans('You get a') +
          ' ${p * db.categories[list[list.length - 1].toString()]} ' +
          Language.of(context).getTrans('L.E') +
          ' ' +
          Language.of(context)
              .getTrans('discount on the next request of Selected Items');
      if (!db.clients[db.company].containsKey('Next Discount')) {
        await db.ref.collection(db.company).doc("Next Discount").set(
            {"value": p * db.categories[list[list.length - 1].toString()]});
      } else {
        DocumentReference documentReference =
            db.ref.collection(db.company).doc('Next Discount');
        FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(documentReference);
          num newFollowerCount = snapshot.data()['value'] +
              p * db.categories[list[list.length - 1].toString()];
          transaction.update(documentReference, {'value': newFollowerCount});
        });
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text(
              Language.of(context).getTrans('Okay'),
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          FlatButton(
            child: Text(
              Language.of(context).getTrans('New Request'),
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                reset();
              });
            },
          )
        ],
      ),
    );
  }

  void cancel(BuildContext context) {
    Navigator.pop(context);
  }

  Future loadImage(Map image) async {
    if (image != null && image.containsKey('Image')) {
      var url = (await FirebaseStorage.instance
          .ref()
          .child(image['Image'])
          .getDownloadURL());
      return pic = Image.network(url);
    }
  }

  void add() {
    setState(() {
      int value = int.parse(quantity.text.toString());
      value++;
      quantity.text = value.toString();
      price = (value * db.medicines[barcode.text]['Pbu']).toString();
    });
  }

  void subtract() {
    setState(() {
      int value = int.parse(quantity.text.toString());
      if (value != 0) {
        value--;
        quantity.text = value.toString();
        price = (value * db.medicines[barcode.text]['Pbu']).toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //dropdownbutton category
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(Language.of(context).getTrans('New Request')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => cancel(context),
          ),
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
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<int>(
                    value: 1,
                    child: (DarkMode.value
                        ? Text(
                            Language.of(context).getTrans('Disable Dark Mode'))
                        : Text(
                            Language.of(context).getTrans('Enable Dark Mode'))),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Text(
                        Language.of(context).getTrans('تغيير اللغة للعربية')),
                  ),
                ];
              },
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  //Search Box for name/الاسم
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.2),
                    child: Row(
                      children: <Widget>[
                        Text(Language.of(context).getTrans('Name: ')),
                        Container(
                          width: 200,
                          height: 75,
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: TypeAheadField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: name,
                            ),
                            onSuggestionSelected: (suggestion) {
                              setState(() {
                                name.text = suggestion.values.toList()[0];
                                barcode.text = suggestion.keys.toList()[0];
                                loading = true;
                              });
                            },
                            itemBuilder: (context, itemData) {
                              return ListTile(
                                title: Text(itemData.values.toList()[0]),
                              );
                            },
                            suggestionsCallback: (pattern) {
                              List s = [];
                              db.medicines.forEach((key, value) {
                                if (name.text != "" &&
                                    value['Name']
                                        .toString()
                                        .toLowerCase()
                                        .startsWith(pattern.toLowerCase())) {
                                  s.add({key: value['Name']});
                                }
                              });
                              return s;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.2),
                    child: Row(
                      children: <Widget>[
                        Text(Language.of(context).getTrans('Barcode: ')),
                        Container(
                          width: 200,
                          height: 75,
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: TextField(
                            controller: barcode,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {
                              loading = true;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //raisedbutton for scan barcode
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: RaisedButton(
                      onPressed: null,
                      child:
                          Text(Language.of(context).getTrans('Scan Barcode')),
                    ),
                  ),
                  //searchbox for distributor
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.2),
                    child: Row(
                      children: <Widget>[
                        Text(Language.of(context).getTrans('Distributor: ')),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        //Quantity
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                onPressed: subtract,
                                icon: Icon(Icons.remove),
                              ),
                              Container(
                                width: 30,
                                height: 75,
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: quantity,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  onChanged: (p) {
                                    setState(() {
                                      price = (int.parse(p) *
                                              db.medicines[barcode.text]["Pbu"])
                                          .toString();
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: add,
                                icon: Icon(Icons.add),
                              )
                            ],
                          ),
                        ),
                        //Price
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(Language.of(context).getTrans('Price: ')),
                              Text(price),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  //card for image
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Card(
                      child: Container(
                        height: 300,
                        width: 500,
                        padding: EdgeInsets.all(20),
                        child: !loading
                            ? Image.asset('images/logo.jpg')
                            : (pic == null)
                                ? FutureBuilder(
                                    future:
                                        loadImage(db.medicines[barcode.text]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.data != null) {
                                        return snapshot.data;
                                      }
                                      return Waiting();
                                    },
                                  )
                                : pic,
                      ),
                    ),
                  ),
                  //Submit
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => submit(context),
          child: Icon(Icons.check),
        ),
      ),
    );
  }
}
