import 'package:dash/AllScreen/registrationScreen.dart';
import 'package:dash/AllWidgets/progressDialog.dart';
import 'package:dash/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'mainScreen.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login";

  final TextEditingController emailTextEditingController= TextEditingController();
  final TextEditingController passwordTextEditingController= TextEditingController();

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 105.0,),
              const Center(child:Text("D",style:TextStyle(fontStyle: FontStyle.normal,fontSize: 120.0,color: Color(0xff00ACA4),fontFamily: "Brand Bolt",
                  fontWeight: FontWeight.bold,)),),
              const SizedBox(
                height:10.0,
              ),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 34,fontWeight: FontWeight.bold,fontFamily: "Brand Bolt"),
              ),
              const Text(
                "Please login to your account",
                style: TextStyle(fontSize: 18,fontFamily: "Brand Bolt",),
              ),
              Padding(padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 1.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Colors.black,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Email Address",
                        hintStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    const  SizedBox(height: 10.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Password",
                        hintStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0,),
                    RaisedButton(
                      textColor: Colors.black,
                      child:Container(
                        color: const Color(0xff00ACA4),
                        height: 60.0,
                        child: const Center(
                          child: Text(
                            "Login",
                            style:  TextStyle(fontFamily: "Brand Bolt", fontSize: 20.0,color: Colors.white),
                          ),
                        ),
                      ),
                      onPressed: (){
                        if(!emailTextEditingController.text.contains("@")){
                          displayToastMessage("Email address is not correct", context);
                        }
                        else if(passwordTextEditingController.text.isEmpty){
                          displayToastMessage("please provide password", context);
                        }
                        else {
                          loginAndAuthenticateUser(context);
                        }
                      },
                    )
                  ],
                ),
              ),
              TextButton(
                onPressed: ()
                {
                  Navigator.pushNamedAndRemoveUntil(context, RegistrationScreen.idScreen, (route) => false);
                },
                child:const Text(
                  "Register here",
                  style:TextStyle(color:Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 130.0,),
              const Center(child:Text(
                "D",
                style: TextStyle(fontSize: 130,fontFamily: "Brand Bolt",color:Color(0xff00ACA4),fontWeight: FontWeight.bold,),
              )),
              const Padding(
                  padding: EdgeInsets.fromLTRB(35, 0, 0, 0),
                  child:Text(
                    "Welcome back!",
                    style: TextStyle(fontSize: 32,fontFamily: "Brand Bolt",color:Colors.black,fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 15,),
              const Padding(
                  padding: EdgeInsets.fromLTRB(35, 0, 0, 0),
                  child:Text(
                    "Please login to Your Account!",
                    style: TextStyle(fontSize: 18,fontFamily: "Brand Bolt"),
                  )),
              Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 15.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Colors.black,
                      decoration: const InputDecoration(
                        fillColor: Color(0xff00ACA4),
                        hintText: "Email Address",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const  SizedBox(height: 15.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        fillColor: Colors.black,
                        hintText: "Password",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const  SizedBox(height: 24.0,),
                    RaisedButton(
                      color: const Color(0xff00ACA4),
                      textColor: Colors.white,
                      child: const SizedBox(
                        height: 50.0,
                        child: Center(
                          child:Text(
                            "Login",
                            style:  TextStyle(fontFamily: "Brand Bolt", fontSize: 18.0),
                          ),
                        ),
                      ),

                      onPressed: (){
                        if(!emailTextEditingController.text.contains("@")){
                          displayToastMessage("Email address is not correct", context);
                        }
                        else if(passwordTextEditingController.text.isEmpty){
                          displayToastMessage("please provide password", context);
                        }
                        else {
                          loginAndAuthenticateUser(context);
                        }
                      },
                    )
                  ],
                ),
              ),
              SizedBox(height: 30,),
              FlatButton(
                onPressed: ()
                {
                  Navigator.pushNamedAndRemoveUntil(context, RegistrationScreen.idScreen, (route) => false);
                },
                child: const Center(child:Text(
                  "Register here",
                  style:TextStyle(color:Colors.black,fontSize: 20),
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;
  void loginAndAuthenticateUser(BuildContext context)async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return ProgressDialog(message: "Authenticating Please Wait...",);
      }
    );
    final User? firebaseUser = (
        await _firebaseAuth.signInWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text).catchError((errMsg){
          Navigator.pop(context);
          displayToastMessage("Error :"+ errMsg.toString(), context);
    })).user;
    if(firebaseUser !=null){
      userRef.child(firebaseUser.uid).once().then((DatabaseEvent snap){
      if(snap.snapshot!=null) {
        Navigator.pushNamedAndRemoveUntil(
            context, MainScreen.idScreen, (route) => false);
        displayToastMessage("your are logged in", context);}
      else{
        Navigator.pop(context);
        _firebaseAuth.signOut();
        displayToastMessage("you don't have an account", context);
      }
      });
    }
    else
    {
      Navigator.pop(context);
      displayToastMessage("no account for this record! please register first", context);
    }
  }

}
