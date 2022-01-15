import 'package:flutter/material.dart';

class CancelledRides extends StatefulWidget {
  @override
  _CancelledRidesState createState() => _CancelledRidesState();
}

class _CancelledRidesState extends State<CancelledRides> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home:Scaffold(
            appBar: AppBar(
              title: Text("Cancelled rides"),
            ),
            body:     Container(
              child:Center(child:Text("no Cancelled Rides Yet")),
            )
        )
    );
  }

  void getCancelledRides(){}


}
