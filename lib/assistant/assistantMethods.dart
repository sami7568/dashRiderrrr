import 'dart:convert';
import 'dart:math';
import 'package:dash/Models/address.dart';
import 'package:dash/Models/allUsers.dart';
import 'package:dash/Models/directionDetails.dart';
import 'package:dash/assistant/requestAssistant.dart';
import 'package:dash/dataHandler/appData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../configMaps.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(Position position,context) async {
    String placeAddress="";
    String st1,st2,st3,st4;
    String url="https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response=await RequestAssistant.getRequest(url);

    if(response!="failed"){
//      placeAddress =response["results"][0]["formatted_address"];
      st1 =response["results"][0]["address_components"][0]["long_name"];
      st3 =response["results"][0]["address_components"][1]["long_name"];
      st4 =response["results"][0]["address_components"][4]["long_name"];
      placeAddress=st1 +", "+st3+", "+st4;
      Address? userPickUpAddress= Address();
      userPickUpAddress.longitude=position.longitude;
      userPickUpAddress.latitude=position.latitude;
      userPickUpAddress.placeName=placeAddress;
      Provider.of<AppData>(context,listen:false).updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetail(LatLng initialPosition,LatLng finalPosition)async
  {
    String directionUrl="https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res= await RequestAssistant.getRequest(directionUrl);
    if(res=="failed"){
      return null!;
    }
    DirectionDetails directionDetails= DirectionDetails();
    directionDetails.encodedPoint=res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText=res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue=res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText=res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue=res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int caluculateFares(DirectionDetails? directionDetails){
    double timeTraveledFares=(directionDetails!.durationValue!/60)*0.20;
    double distanceTraveledFares=(directionDetails.distanceValue!/1000)*0.20;
    double totalFareAmmount=(timeTraveledFares+distanceTraveledFares);

    if(carRideType=="sharing"){
      totalFareAmmount=totalFareAmmount/4;
      return totalFareAmmount.truncate() * noOfPassengers;
    }
    else{
      return totalFareAmmount.truncate();
    }
    // local currency
    // 1$=160
    // double totalLocalAmmount=  totalFareAmmount*160;
  }

  static calculateFareEco(DirectionDetails? directionDetails){
    double basseFareEco=4;
    double perDistanceEco=1.4;
    double perTimeEco=0.28;
    double minimumFareEco=8.5;
    double timeTraveledFares=(directionDetails!.durationValue!/60)* perDistanceEco;
    double distanceTraveledFares=(directionDetails.distanceValue!/1000)* perTimeEco;
    double totalFareAmmount=(timeTraveledFares+distanceTraveledFares) + basseFareEco;

    if(totalFareAmmount < minimumFareEco){
      return minimumFareEco.truncate();
    }
    else
    {
      return totalFareAmmount.truncate();
    }

  }
  static calculateFareStandard(DirectionDetails? directionDetails){
    double basseFareStandard=6.5;
    double perDistanceStandard=1.35;
    double perTimeStandard=0.43;
    double minimumFareStandard=15.0;
    double timeTraveledFares=(directionDetails!.durationValue!/60)* perDistanceStandard;
    double distanceTraveledFares=(directionDetails.distanceValue!/1000)* perTimeStandard;
    double totalFareAmmount=(timeTraveledFares+distanceTraveledFares) + basseFareStandard;

    if(totalFareAmmount < minimumFareStandard){
      return minimumFareStandard.truncate();
    }
    else
    {
      return totalFareAmmount.truncate();
    }

  }
  static calculateFareLuxe(DirectionDetails? directionDetails){
    double basseFareluxe=10.0;
    double perDistanceluxe=2.0;
    double perTimeluxe=0.95;
    double minimumFareluxe=22.5;
    double timeTraveledFares=(directionDetails!.durationValue!/60)* perDistanceluxe;
    double distanceTraveledFares=(directionDetails.distanceValue!/1000)* perTimeluxe;
    double totalFareAmmount=(timeTraveledFares+distanceTraveledFares) + basseFareluxe;

    if(totalFareAmmount < minimumFareluxe){
      return minimumFareluxe.truncate();
    }
    else
    {
      return totalFareAmmount.truncate();
    }

  }

  static getCurrentOnlineUserInfo() async
  {
    firebaseUser=await FirebaseAuth.instance.currentUser;
    String userId=firebaseUser!.uid;
    DatabaseReference reference=  FirebaseDatabase.instance.reference().child("users").child(userId);
    reference.once().then((DatabaseEvent dataSnapShot) {
      if(dataSnapShot.snapshot.value!= null){
        userCurrentInfo=Users.fromSnapShot(dataSnapShot.snapshot);
      }
    });
  }

  static double createRandomNumber(int num){
    var random=Random();
    int radNumber= random.nextInt(num);
    return radNumber.toDouble();

  }

  static sendNotificationDriver(String token, context,String ride_request_id)async{
    print("sending to driver 123");
    var destination= await Provider.of<AppData>(context,listen: false).dropOffLocation;
    print("drop Off location");
    print(destination);

    Map<String,String> headerMap ={
      'Content-Type':'application/json',
      'Authorization': serverToken,
    };
    Map NotificationMap={
      'body':'DropOff Location, ${destination!.placeName}',
      'title':'new ride request',
    };
    Map dataMap={
      'click-action':'FLUTTER_NOTIFICATION_CLICK',
      'id':'1',
      'status':'done',
      'ride_request_id':ride_request_id
    };
    Map sendNotificationMap = {
      "notification": NotificationMap,
      "data": dataMap,
      "priority": "high",
      "to": token,
    };
    print("fcm messaage sending");

    var res= await http.post(Uri.parse(
      'https://fcm.googleapis.com/fcm/send'),
      headers: headerMap,
      body: jsonEncode(sendNotificationMap),
    );
    print("fcm result");
    print(res);
  }
}


