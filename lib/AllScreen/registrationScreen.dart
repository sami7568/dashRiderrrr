import 'package:dash/AllWidgets/progressDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../main.dart';
import 'loginScreen.dart';
import 'mainScreen.dart';

class RegistrationScreen extends StatelessWidget {
  static const String idScreen = "registration";
  final GlobalKey<ScaffoldState> scaffoldKey=new GlobalKey<ScaffoldState>();

  void showSnackBar(String title){
    final snackBar=SnackBar(
      content: Text(title,textAlign: TextAlign.center,style:TextStyle(fontSize: 15.0,),),
    );
    scaffoldKey.currentState!.showSnackBar(snackBar);
  }

  TextEditingController nameTextEditingController= TextEditingController();
  TextEditingController emailTextEditingController= TextEditingController();
  TextEditingController passwordTextEditingController= TextEditingController();
  TextEditingController confirmPasswordTextEditingController= TextEditingController();
  TextEditingController phoneTextEditingController= TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 30.0,),
            Text("D",style:TextStyle(color: Color(0xff00ACA4),fontFamily: "Brand Bolt",fontSize: 50,fontWeight: FontWeight.bold)),

              const Text(
                "Registration",
                style: TextStyle(fontSize: 45,fontFamily: "Brand Bolt",fontWeight: FontWeight.bold),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType:TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Email Address",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                     const SizedBox(height: 10.0,),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "User Name",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                     const SizedBox(height: 10.0,),
                    TextField(
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: phoneTextEditingController,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Mobile Number",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                     const SizedBox(height: 10.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Password",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: confirmPasswordTextEditingController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        hintText: "Confirm Password",
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0,),
                    RaisedButton(
                      color: const Color(0xff00ACA4),
                      child: const SizedBox(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            "REGISTER",
                            style:  TextStyle(fontFamily: "Brand Bolt", fontSize: 18.0,color: Colors.white),
                          ),
                        ),
                      ),
                      onPressed: (){
                        validateData(context);
                      },
                    ),
                  ],
                ),
              ),
              FlatButton(
                  onPressed: ()
                  {
                    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                  },
                  child: const Center(child:Text(
                      "Already have an account? Login here",
                      style:TextStyle(color: Colors.black)
                  ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;
  validateData(BuildContext context){
    if(!emailTextEditingController.text.contains("@")){
      displayToastMessage("Email address is not correct", context);
      return;
    }
    if(nameTextEditingController.text.length<=3){
      displayToastMessage("name must be at least 3 characters", context);
      return;
    }
    else if(phoneTextEditingController.text.isEmpty){
      displayToastMessage("Phone Number is mandatory", context);
      return;
    }
    else if(passwordTextEditingController.text.length<6){
      displayToastMessage("Password is too short must be at least 6 characters", context);
      return;
    }
    else if(confirmPasswordTextEditingController.text.isEmpty){
      displayToastMessage("Confirm Password is mandatory", context);
      return;
    }
    else if(passwordTextEditingController.text != confirmPasswordTextEditingController.text){
      displayToastMessage("Password and Confirm password are not same", context);
      return;
    }
    else{
      registerNewUser(context);
    }
  }
  void registerNewUser(BuildContext context)async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return ProgressDialog(message: "Registering Please Wait",);
        }
    );

    final  UserCredential firebaseUser = (await _firebaseAuth
        .createUserWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text).catchError((errMsg){
      Navigator.pop(context);
          displayToastMessage("Error :"+ errMsg.toString(), context);
    }));

    if(firebaseUser !=null){
      Map userDataMap= {
        "name":nameTextEditingController.text.trim(),
        "email":emailTextEditingController.text.trim(),
        "phone":phoneTextEditingController.text.trim(),
        "password":passwordTextEditingController.text.trim(),
      };
      userRef.child(firebaseUser.user!.uid).set(userDataMap);
      displayToastMessage("Congrates your account is created", context);
      Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
    }
    else
      {
        Navigator.pop(context);
        displayToastMessage("New User Account has Not been created", context);
      }
  }
}

displayToastMessage(String message,BuildContext context){
  Fluttertoast.showToast(msg: message);
}
