import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

import '../configMaps.dart';


class RatingScreen extends StatefulWidget {
  final String? driverId;
  RatingScreen({this.driverId});
  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body:Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(15.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.0,),
              Text(
                "Rate this Driver",
                style: TextStyle(fontSize: 20.0,fontFamily: "Brand Bolt",color: Colors.black54),
              ),
              SizedBox(height: 22.0,),
              Divider(height: 2.0,thickness: 2.0,),
              SizedBox(height: 16.0,),
              SmoothStarRating(
                rating: starCounter,
                color: Colors.green,
                allowHalfRating: false,
                starCount: 5,
                size: 45,
                onRated: (value){
                  starCounter=value;
                  if(starCounter==1){
                    setState(() {
                      title="Very Bad";
                    });
                  }
                  if(starCounter==2){
                    setState(() {
                      title="Bad";
                    });
                  }
                  if(starCounter==3){
                    setState(() {
                      title="Good";
                    });
                  }
                  if(starCounter==4){
                    setState(() {
                      title="Very Good";
                    });
                  }
                  if(starCounter==5){
                    setState(() {
                      title="Excellent";
                    });
                  }
                },
              ),
              SizedBox(height: 14.0,),
              Text(title,style: TextStyle(fontSize: 55.0,fontFamily: "Brand Bolt",color: Colors.green),),
              SizedBox(height: 16.0,),
              Padding(
                padding:EdgeInsets.symmetric(horizontal: 16.0),
                child: RaisedButton(
                  onPressed: ()async {
                    DatabaseReference driverRatingRef=FirebaseDatabase.instance.reference()
                        .child("drivers")
                        .child(widget.driverId!)
                        .child("ratings");
                    driverRatingRef.once().then((DatabaseEvent dataSnapshot){
                      if(dataSnapshot.snapshot.value!=null){
                        double olddRatings = double.parse(dataSnapshot.snapshot.value.toString());
                        double addRatings= olddRatings + starCounter;
                        double averageRatings= addRatings/2;
                        driverRatingRef.set(averageRatings.toString());
                       }
                      else{
                        driverRatingRef.set(starCounter.toString());
                      }
                    });
                    Navigator.pop(context);
                  },
                  color: Colors.deepPurple,
                  child: Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Submit",style: TextStyle(fontSize: 20.0,fontFamily: "Brand Bolt",fontWeight: FontWeight.bold,color: Colors.white),),
                        Icon(Icons.attach_money,color: Colors.white,size: 26,),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0,),
            ],
          ),

        ),
      )
    );
  }
}
