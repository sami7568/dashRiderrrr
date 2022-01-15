import 'package:flutter/material.dart';

class AcceptedRides extends StatefulWidget {
  @override
  _AcceptedRidesState createState() => _AcceptedRidesState();
}

class _AcceptedRidesState extends State<AcceptedRides> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home:Scaffold(
            appBar: AppBar(
              title: Text("Accepted rides"),
            ),
            body:     Container(
              child:Center(child:Text("no Accepted Rides Yet")),
            )
        )
    );
  }

  void getAcceptedRides(){}
}
