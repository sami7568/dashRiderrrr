import 'package:dash/AllScreen/mainScreen.dart';
import 'package:dash/AllScreen/registrationScreen.dart';
import 'package:dash/AllWidgets/progressDialog.dart';
import 'package:dash/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../configMaps.dart';

class ProfilePage extends StatefulWidget {
  static const String idScreen = "profile";
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
  TextEditingController phoneTextEditingController= TextEditingController();


  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile Page"),),
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              SizedBox(height: 30.0,),
/*              Center(child:Text("QAF",style:TextStyle(fontSize: 30.0,fontFamily: "Brand Bolt",fontWeight: FontWeight.bold,
                  color: Colors.black87)),),*/
              Image(
                image: AssetImage("images/user_icon.png"),width: 150,height: 150,),
              SizedBox(height:20),
              SizedBox(
                height:10.0,
              ),
              Padding(padding: EdgeInsets.all(10),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 10.0,),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      cursorColor: Colors.black87,
                      decoration: InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        labelText:"Name",
                        hintText: "e.g: Albert John",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(23.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black87,width: 2.0),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        labelStyle: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black87
                        ),
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        labelText:"Email",
                        hintText: "e.g: john@gmail.com",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(23.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black87,width: 2.0),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        labelStyle: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black87
                        ),
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        labelText:"Phone",
                        hintText: "e.g: 03219030930",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(23.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black87,width: 2.0),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        labelStyle: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black87
                        ),
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        fillColor: Color(0x225C0D0D),
                        labelText:"password",
                        hintText: "e.g: ******",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(23.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black87,width: 2.0),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        labelStyle: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black87
                        ),
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0,),
                    RaisedButton(
                      color: Color(0xFF45b6fe),
                      textColor: Colors.black87,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            "Update Profile",
                            style:  TextStyle(fontFamily: "Brand Bolt", fontSize: 18.0),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24),
                      ),
                      onPressed: (){
                        if(nameTextEditingController.text.length<3){
                          //displayToastMessage("name must be at least 3 characters", context);
                          showSnackBar("name must be at least 3 characters.");
                          return;
                        }
                        else if(!emailTextEditingController.text.contains("@")){
                          //displayToastMessage("Email address is not correct", context);
                          showSnackBar("Please provide a correct email address");
                          return;
                        }
                        else if(phoneTextEditingController.text.length <10 ){
                          //displayToastMessage("Please Provide a valid Phone Number", context);
                          showSnackBar("Please provide a valid phone number");
                          return;
                        }
                        else if(passwordTextEditingController.text.length<6 ){
                          showSnackBar("password is too short must be at least 6 charaters");
                          //displayToastMessage("Password is too short must be at least 6 characters", context);
                          return;
                        }
                        else{
                          registerNewUser(context);
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void getUserData(){
    DatabaseReference userRef=FirebaseDatabase.instance.reference().child("users");
    userRef.child(firebaseUser!.uid).once().then((DatabaseEvent snapshot) {

      Map values = snapshot.snapshot.value as Map;
      String name = values["name"].toString();
      String email = values["email"].toString();
      String phone = values["phone"].toString();
      String password = values["password"].toString();
       setState(() {
         nameTextEditingController.text = name;
         emailTextEditingController.text = email;
         phoneTextEditingController.text = phone;
         passwordTextEditingController.text = password;
       });
    }
    );

  }

  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;
  void registerNewUser(BuildContext context)async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return ProgressDialog(message: "Updating Profile...",);
        }
    );

    if(firebaseUser !=null){
        String name=nameTextEditingController.text.trim();
        String email=emailTextEditingController.text.trim();
        String phone=phoneTextEditingController.text.trim();
        String password=passwordTextEditingController.text.trim();

      userRef.child(firebaseUser!.uid).child("name").set(name);
        userRef.child(firebaseUser!.uid).child("email").set(email);
        userRef.child(firebaseUser!.uid).child("phone").set(phone);
        userRef.child(firebaseUser!.uid).child("password").set(password);


        displayToastMessage("Your Profile is Updated", context);
        Navigator.push(context, MaterialPageRoute(builder: (context)=>MainScreen()));
  //    Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
    }
    else
    {
      Navigator.pop(context);
      displayToastMessage("Your Profile is updated", context);
    }
  }

}

