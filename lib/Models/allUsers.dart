import 'package:firebase_database/firebase_database.dart';

class Users{
  String? id;
  String? name;
  String? email;
  String? phone;
  Users({this.id,this.name,this.email,this.phone});

  Users.fromSnapShot(DataSnapshot dataSnapshot){
    id=dataSnapshot.key;
    Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
    name=values["name"];
    email=values["email"];
    phone=values["phone"];

  }

}