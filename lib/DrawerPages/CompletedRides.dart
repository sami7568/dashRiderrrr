import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CompleteRides extends StatefulWidget {
  @override
  _CompleteRidesState createState() => _CompleteRidesState();
}

class _CompleteRidesState extends State<CompleteRides> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        appBar: AppBar(
          title: Text("completed rides"),
        ),
        body:     Container(
          child:Center(child:Text("no Completed Rides Yet")),
        )
      )
    );
  }

  void getCompletedRides(){
    DatabaseReference rideRequst = FirebaseDatabase.instance.reference().child("rideRequest");
  }
}
