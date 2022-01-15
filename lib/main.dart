// @dart=2.9

import 'package:dash/dataHandler/appData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'AllScreen/loginScreen.dart';
import 'AllScreen/mainScreen.dart';
import 'AllScreen/registrationScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

}

DatabaseReference userRef=FirebaseDatabase.instance.reference().child("users");
DatabaseReference driversRef=FirebaseDatabase.instance.reference().child("drivers");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=>AppData(),
      child: MaterialApp(
        title: 'Rider App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          accentColor: Color(0xff00ACA4),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: FirebaseAuth.instance.currentUser==null? LoginScreen.idScreen: MainScreen.idScreen,
        routes: {
          RegistrationScreen.idScreen: (context) => RegistrationScreen(),
          LoginScreen.idScreen: (context) => LoginScreen(),
          MainScreen.idScreen :(context) => MainScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
