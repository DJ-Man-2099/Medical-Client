import 'package:flutter/material.dart';


class Waiting extends StatefulWidget {
  @override
  _WaitingState createState() => _WaitingState();
}

class _WaitingState extends State<Waiting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
            height: 300.0,
            width: 300.0,
            child:
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue),
                strokeWidth: 5.0)
        ),
      ),
    );
  }
}
