
import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {

 final String? message;
  ProgressDialog({this.message});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        margin: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: <Widget>[
              SizedBox(width: 6.0,),
              CircularProgressIndicator( valueColor: AlwaysStoppedAnimation<Color>(Color(0xff00ACA4)),),
              SizedBox(width: 26.0,),
              Text(
                message!,
                style: TextStyle(color: Color(0xff00ACA4),fontSize: 10.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
