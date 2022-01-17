import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dash/AllScreen/ratingScreen.dart';
import 'package:dash/AllScreen/registrationScreen.dart';
import 'package:dash/AllScreen/searchScreen.dart';
import 'package:dash/AllWidgets/collectFareDialog.dart';
import 'package:dash/AllWidgets/divider.dart';
import 'package:dash/AllWidgets/noDriverAvailableDialog.dart';
import 'package:dash/AllWidgets/progressDialog.dart';
import 'package:dash/DrawerPages/AcceptedRequest.dart';
import 'package:dash/DrawerPages/CancelledRides.dart';
import 'package:dash/DrawerPages/CompletedRides.dart';
import 'package:dash/DrawerPages/ProfilePage.dart';
import 'package:dash/Models/directionDetails.dart';
import 'package:dash/Models/nearbyAvailableDrivers.dart';
import 'package:dash/assistant/assistantMethods.dart';
import 'package:dash/assistant/geoFireAssistants.dart';
import 'package:dash/configMaps.dart';
import 'package:dash/dataHandler/appData.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'loginScreen.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "main";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  DirectionDetails? tripDirectionDetails;

  List <LatLng> pLineCoordinates=[];
  Set<Polyline>   polyLineSet={};
  Position? currentPosition;
  var geolocator= Geolocator();
  double bootomPaddingOfMap=0;

  Set<Marker> markerSet={};
  Set<Circle> circleSet={};


  double rideDetailsContainerHeight=0;
  double requestRideContainerHeight=0;
  double searchContainerHeight=280.0;
  double driverDetailsContainersHeight=0;
  double confirmNoOfPassengersHeight=0;

  bool drawerOpen=true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference? rideRiquestRef;
  BitmapDescriptor? nearByIcon;
  List<NearbyAvailableDrivers>? availableDrivers;
  String? token;
  String state="normal";

  StreamSubscription<DatabaseEvent>? ridestreamSubscription;
  bool isRequestingPositionDetails=false;
  String uName="";

  TextEditingController passengerController= new TextEditingController();

  @override
  void initState() {
    // TODO: implement initState

    locatePosition();
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest(){
    rideRiquestRef=FirebaseDatabase.instance.reference().child("rideRequest").push();

    var pickUp=Provider.of<AppData>(context,listen: false).pickUpLocation;
    var dropOff=Provider.of<AppData>(context,listen: false).dropOffLocation;

    Map pickUpLocMap={
      "latitude":pickUp!.latitude.toString(),
      "longitude":pickUp.longitude.toString(),
    };

    Map dropOffLocMap={
      "latitude":dropOff!.latitude.toString(),
      "longitude":dropOff.longitude.toString(),
    };

    Map rideinInfoMap={
      "driver_id":"waiting",
      "payment_method":"cash",
      "pickUp":pickUpLocMap,
      "dropOff":dropOffLocMap,
      "created_at":DateTime.now().toLocal().toString(),
      "rider_name": userCurrentInfo!.name,
      "rider_phone": userCurrentInfo!.phone,
      "pick_Up_Address": pickUp.placeName,
      "drop_Off_Location": dropOff.placeName,
      "ride_type":carRideType,
    };
    rideRiquestRef!.set(rideinInfoMap);

    ridestreamSubscription = rideRiquestRef!.onValue.listen(( DatabaseEvent event) async {
      if(event.snapshot.value==null){
       return;
      }
      Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
      if(values['car_deails'] != null){
       setState(() {
         carDetailDriver =values["car_details"].toString();
       });
      }
      if(values["driver_name"]!=null){
        setState(() {
          driverName =values["driver_name"].toString();
        });
      }
      if(values["driver_phone"]!=null){
        setState(() {
          driverPhone =values["driver_phone"].toString();
        });
      }
      if(values["driver_location"]!=null){

          double driverLat = double.parse(values["driver_location"]["latitude"].toString());
          double driverLng = double.parse(values["driver_location"]["longitude"].toString());
          LatLng driverCurrentLocation=LatLng(driverLat,driverLng);

          if(statusRide=="accepted"){
            updateRideTimeToPickUpLocation(driverCurrentLocation);
          }
          else if(statusRide=="onride"){
            updateRideTimeToDropOffLocation(driverCurrentLocation);
          }
          else if(statusRide=="arrived"){
            setState(() {
              rideStatus="Driver has Arrived.";
            });
          }
      }
      if(values["status"]!=null){
        statusRide =values["status"].toString();
      }
      if(statusRide=="accepted"){
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofireMarkers();
      }
      if(statusRide=="ended"){
        if(values["fares"]!=null){
          int fare=int.parse(values["fares"].toString());
          var res=await showDialog(
            context:context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectFareDialog(paymentMethod:"Cash",fareAmount: fare),
          );
          String driverId="";
          if(res=="close"){
            if(values["driver_id"]!=null){
              driverId=values['driver_id'].toString();
            }

            Navigator.of(context).push(MaterialPageRoute(builder:(context) => RatingScreen(driverId:driverId)));
            rideRiquestRef!.onDisconnect();
            rideRiquestRef=null;
            ridestreamSubscription!.cancel();
            ridestreamSubscription=null;
            resetApp();
            statusRide="";
            driverName="";
            driverPhone="";
            carDetailDriver="";
            rideStatus="";
            driverDetailsContainersHeight=0.0;
          }
        }
      }
    });
  }

  void deleteGeofireMarkers(){
    setState(() {
      markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLocation(LatLng driverCurrentLocation)async
  {
    if(isRequestingPositionDetails==false){
      isRequestingPositionDetails=true;
      var positionUserLatLng=LatLng (currentPosition!.latitude,currentPosition!.longitude);
      var details =await AssistantMethods.obtainPlaceDirectionDetail(driverCurrentLocation, positionUserLatLng);
      if(details==null){
        return;
      }
      setState(() {
        rideStatus="Driver is Coming: "+details.durationText!;
      });
      isRequestingPositionDetails=false;
    }
  }

  void updateRideTimeToDropOffLocation(LatLng driverCurrentLocation)async
  {
    if(isRequestingPositionDetails==false){
      isRequestingPositionDetails=true;

      var dropOff =Provider.of<AppData>(context,listen:false).dropOffLocation;
      var dropOffUserLatLng=LatLng (dropOff!.latitude!,dropOff.longitude!);

      var details=await AssistantMethods.obtainPlaceDirectionDetail(driverCurrentLocation, dropOffUserLatLng);
      if(details==null){
        return;
      }
      setState(() {
        rideStatus="Going To Destination - "+details.durationText!;
      });
      isRequestingPositionDetails=false;
    }
  }

  void cancleRideRequest(){
    rideRiquestRef!.remove();
    print("cancel ride");
    setState(() {
      state="normal";
    });
    resetApp();
  }

  void displayRequestRideContainer(){
    setState(() {
      requestRideContainerHeight= 250.0;
      rideDetailsContainerHeight= 0.0;
      bootomPaddingOfMap=230.0;
      drawerOpen=true;
    });
   saveRideRequest();
  }

  void displayConfirmPassengersContainer(){
    setState(() {
      requestRideContainerHeight= 0.0;
      rideDetailsContainerHeight= 0.0;
      bootomPaddingOfMap=210.0;
      confirmNoOfPassengersHeight=(Platform.isAndroid)?200.0:180;
      driverDetailsContainersHeight=0.0;
    });
  }

  void displayDriverDetailsContainer(){
    setState(() {
      requestRideContainerHeight= 0.0;
      rideDetailsContainerHeight= 0.0;
      bootomPaddingOfMap=290.0;
      driverDetailsContainersHeight=260.0;
    });
  }

  resetApp(){
    setState((){
    drawerOpen =true;
    searchContainerHeight=(Platform.isAndroid)?280:300.0;
    bootomPaddingOfMap=(Platform.isAndroid)?280.0:270;
    rideDetailsContainerHeight=.0;
    requestRideContainerHeight=0;
    polyLineSet.clear();
    markerSet.clear();
    circleSet.clear();
    pLineCoordinates.clear();
    });
   // locatePosition();
  }

  void displayRideDetailsContainer()async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight=0.0;
      rideDetailsContainerHeight=380.0;
      bootomPaddingOfMap=320.0;
      drawerOpen=false;
    });
  }

  void locatePosition() async {
   print('location position ');
    // add code for permission handling
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position? position;
    try{
      position= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    }catch(e){
      print("current location not obtain");
      displayToastMessage("please check your location access ", context);
       position = (await Geolocator.getLastKnownPosition(forceAndroidLocationManager: false))!;
       print(position.latitude);
       print("last  known location");
      print(e);
    }
    currentPosition= position;
    print(position);
     print("mainScreen this is address: ");
    print(position);

    LatLng latLatPosition=LatLng(position.latitude,position.longitude);
    print(position.latitude);
    CameraPosition cameraPosition= new CameraPosition(target: latLatPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address= await AssistantMethods.searchCoordinateAddress(position,context);
    print("this is your address " +address);

    initGeofirelistner();
    uName=userCurrentInfo!.name.toString();
  }

  void seclocatePosition() async {
    print('location position ');
    // add code for permission handling
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position? position;
    try{
      position= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    }catch(e){
      print("current location not obtain");
      displayToastMessage("please check your location access ", context);
      position = (await Geolocator.getLastKnownPosition(forceAndroidLocationManager: false))!;
      print(position.latitude);
      print("last  known location");
      print(e);
    }
    setState(() {
      currentPosition= position;
    });
    print(position);
    print("mainScreen this is address: ");
    print(position);

    LatLng latLatPosition=LatLng(position.latitude,position.longitude);
    print(position.latitude);
    CameraPosition cameraPosition= new CameraPosition(target: latLatPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));


    String address= await AssistantMethods.searchCoordinateAddress(position,context);
    print("this is your address " +address);

    initGeofirelistner();
    setState(() {
      uName=userCurrentInfo!.name.toString();
    });
  }
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(34.015137, 71.524918),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    craeateIconMarker();
   // seclocatePosition();
    return Scaffold(
      key: scaffoldKey,
      //drawer of app
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                color: Color(0xff00ACA4),
                height: 150.0,
                child: DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xff00ACA4)),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                     const SizedBox(width: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (uName.isEmpty) ? "User Name" :uName.toUpperCase() ,
                            style:const TextStyle(
                                fontSize: 16.0,
                                fontFamily: "Brand Bolt",
                                color: Colors.white),
                          ),
                          SizedBox(height: 6.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfilePage()));
                            },
                            child: const Text(
                              " Go to Profile",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  textBaseline: TextBaseline.alphabetic),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              // drawer body controller
              GestureDetector(
                onTap: () {
                  displayToastMessage("Not Avaiable ", context);
                  Navigator.pop(context);
                },
                child: const ListTile(
                  leading: Icon(Icons.inbox_sharp),
                  title: Text(
                    "Inbox",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AcceptedRides()));
                },
                child: const ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    "Accept Requests",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CompleteRides()));
                  },
                  child: const ListTile(
                    leading: Icon(Icons.info),
                    title: Text(
                      "Completed Rides",
                      style: TextStyle(fontSize: 15.0),
                    ),
                  )),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CancelledRides()));
                  },
                  child: const ListTile(
                    leading: Icon(Icons.info),
                    title: Text(
                      "Cancelled Rides",
                      style: TextStyle(fontSize: 15.0),
                    ),
                  )),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              GestureDetector(
                onTap: () {},
                child: const ListTile(
                  leading: Icon(Icons.payment),
                  title: Text(
                    "Payment History",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, ProfilePage.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    "Profile",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.close),
                  title: Text(
                    "Logout",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 150),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Center(
                      child: Text("All rights reserved"),
                    ),
                    SizedBox(width: 20),
                    Center(
                        child: Text(
                          "v1.0.0",
                        )),
                  ])
            ],
          ),
        ),
      ),

      // body
      body: Stack(
        children: [
          GoogleMap(  // googlemap
            padding: EdgeInsets.only(bottom: bootomPaddingOfMap,top: 50.0),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            markers: markerSet,
            circles: circleSet,
            polylines: polyLineSet,
            onMapCreated:(GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              locatePosition();
              setState(() {
                bootomPaddingOfMap= (Platform.isAndroid)?255.0:250;
              });
            },
          ),

          //Menu Button
          Positioned(
            top: 70.0,
            left: 32.0,
            child: GestureDetector(
              onTap: (){
                if(drawerOpen){
                  scaffoldKey.currentState!.openDrawer();
                }
                else{
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen)? Icons.menu: Icons.close,color: Colors.black,),
                ),
              ),
            ),
          ),

          //SearchSheet
          Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: AnimatedSize(
                vsync: this,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration:const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical:  18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      const  SizedBox(height: 6.0,),
                        GestureDetector(
                          onTap: ()async
                          {
                            print('search');
                            var res =  await Navigator.push(context, MaterialPageRoute(builder:(context)=> (SearchScreen())));
                            print(res);
                            if(res == "obtainDirection"){
                             displayRideDetailsContainer();
                            }
                            else{
                              print("result not out");
                            }
                            },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: const[
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7,0.7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children:const [
                                  Icon(Icons.place_outlined,color: Color(0xff00ACA4),),
                                  SizedBox(width:9.0,),
                                  Text("Where to ",style: TextStyle(fontSize: 18.0),),
                                ],
                              ),
                            ),
                          ),
                        ),
//                        const SizedBox(height: 15.0,),
                      ListTile(
                        leading:const Icon(Icons.home, color:Color(0xff00ACA4),),
                        title:    Text(
                          Provider.of<AppData>(context).pickUpLocation !=null
                              ?Provider.of<AppData>(context).pickUpLocation!.placeName!
                              :"Add Home ",overflow: TextOverflow.ellipsis,style: const TextStyle(fontWeight: FontWeight.bold),),
                        subtitle:const Text("Your Current Address", style:TextStyle(color:Colors.black,fontSize:15.0,),),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,color: Color(0xff00ACA4),),
                      ),
           /*             Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.home, color:Color(0xff00ACA4),),
                              const SizedBox(width: 10,),
                              Expanded(child:Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children:[
                                  Text(
                                    Provider.of<AppData>(context).pickUpLocation !=null
                                        ?Provider.of<AppData>(context).pickUpLocation!.placeName!
                                        :"Add Home ",overflow: TextOverflow.ellipsis,style: const TextStyle(fontWeight: FontWeight.bold),),
                                  const SizedBox(height: 3.0,),
                                  const Text("Your Current Address", style:TextStyle(color:Colors.black,fontSize:15.0,),),
                                ],
                              ),),
                            ],
                          ),
                        ),
           */
                        const ListTile(
                          leading: Icon(Icons.watch_later_outlined,color: Color(0xff00ACA4),),
                          title: Text("LRT Tasik Selaten (Sp14)",style: TextStyle (color: Colors.black,fontWeight: FontWeight.bold ),),
                          subtitle: Text("jalan Lingan Tengam 2.400, W.P Kaula Lampur"),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,color: Color(0xff00ACA4),),
                        ),
                        const ListTile(
                          leading: Icon(Icons.watch_later_outlined,color: Color(0xff00ACA4),),
                          title: Text("LRT Tasik Selaten (Sp14)",style: TextStyle (color: Colors.black,fontWeight: FontWeight.bold ),),
                          subtitle: Text("jalan Lingan Tengam 2.400, W.P Kaula Lampur"),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,color: Color(0xff00ACA4),),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ),

          //cartypes sheet
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration:const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20,10, 10, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Suggested Rides",style: TextStyle (color: Colors.black,fontSize: 18),),
                      const SizedBox(height: 10,),
                      //this one is for eco car
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = "requesting";
                            carRideType = "mvp";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistants.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                              child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "MVP",
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                fontFamily: "Brand Bolt"),
                                          ),
                                          const Text(
                                            ("6 seats"),
                                            style: TextStyle(
                                                fontSize: 15.0, color: Colors.black),
                                          ),
                                         const SizedBox(height: 10,),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                            Text(
                                              ((tripDirectionDetails != null)
                                                  ? 'MYR ${AssistantMethods.calculateFareEco(tripDirectionDetails)}'
                                                  : 'MYR 8.5'),
                                              style: const TextStyle(color: Color(0xff00ACA4),fontWeight: FontWeight.bold,fontFamily: "Brand Bolt"),
                                            ),
                                            const SizedBox(width: 20,),
                                            const Icon(Icons.watch_later_outlined),
                                              SizedBox(width: 10,),
                                              Text(tripDirectionDetails==null?"0 mins": "${(tripDirectionDetails!.durationValue!/60).toInt()}"+" mins", style: TextStyle(fontFamily: "Brand Bolt"),
                                            )
                                          ],)
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Image.asset(
                                            "images/mvp.png",
                                            height: 70.0,
                                            width: 80.0,
                                          ),
                                        ],
                                      ),
                                    ],
                            )),
                          ),
                      ),
                      SizedBox(height: 5,),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = "requesting";
                            carRideType = "basic";
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeoFireAssistants.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          width: double.infinity,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "BASIC",
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontFamily: "Brand Bolt"),
                                      ),
                                      const Text(
                                        ("4 seats"),
                                        style: TextStyle(
                                            fontSize: 15.0, color: Colors.black),
                                      ),
                                      SizedBox(height: 10,),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            ((tripDirectionDetails != null)
                                                ? 'MYR ${AssistantMethods.calculateFareEco(tripDirectionDetails)}'
                                                : 'MYR 8.5'),
                                            style: TextStyle(color: Color(0xff00ACA4),fontWeight: FontWeight.bold,fontFamily: "Brand Bolt"),
                                          ),
                                          SizedBox(width: 20,),
                                          const Icon(Icons.watch_later_outlined),
                                          SizedBox(width: 10,),
                                          Text(tripDirectionDetails==null?"0 mint" :
                                            "${(tripDirectionDetails!.durationValue!/60).toInt()}"+" mins", style: TextStyle(fontFamily: "Brand Bolt"),
                                          )
                                        ],)
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Image.asset(
                                        "images/basic.png",
                                        height: 70.0,
                                        width: 80.0,
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ),
                      ),
                      SizedBox(height: 5,),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = "requesting";
                            carRideType = "MOTERCYCLE";
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeoFireAssistants.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          width: double.infinity,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Bike",
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontFamily: "Brand Bolt"),
                                      ),
                                      const Text(
                                        ("1 seats"),
                                        style: TextStyle(
                                            fontSize: 15.0, color: Colors.black),
                                      ),
                                      SizedBox(height: 10,),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            ((tripDirectionDetails != null)
                                                ? 'MYR ${AssistantMethods.calculateFareEco(tripDirectionDetails)}'
                                                : 'MYR 8.5'),
                                            style: TextStyle(color: Color(0xff00ACA4),fontWeight: FontWeight.bold,fontFamily: "Brand Bolt"),
                                          ),
                                          SizedBox(width: 20,),
                                          const Icon(Icons.watch_later_outlined),
                                          const SizedBox(width: 10,),
                                          Text( tripDirectionDetails==null?"0 mint" :
                                            "${(tripDirectionDetails!.durationValue!/60).toInt()} mints", style: TextStyle(fontFamily: "Brand Bolt"),
                                          )
                                        ],)
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Image.asset(
                                        "images/bike.png",
                                        height: 70.0,
                                        width: 80.0,
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          //searching sheet
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius:  BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7,0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12.0,),
                    SizedBox(
                      width: double.infinity,
                      // ignore: deprecated_member_use
                      child: ColorizeAnimatedTextKit(
                      onTap: () {
                      },
                      text: const [
                          "Requesting Ride...",
                          "Please Wait...",
                          "Finding a Driver...",
                          ],
                      textStyle: const TextStyle(
                          fontSize: 35.0,
                          fontFamily: "Signatra"
                          ),
                      colors: const [
                        Colors.green,
                        Colors.pink,
                        Colors.purple,
                        Colors.blue,
                        Colors.yellow,
                        Colors.red,
                      ],
                      textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22.0,),
                    GestureDetector(
                      onTap: (){
                        cancleRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0,color: Colors.grey[300]!),
                        ),
                        child: const Icon(Icons.close, size: 26.0,),
                      ),
                    ),
                    const SizedBox(height: 22.0,),
                    const SizedBox(
                      width: double.infinity,
                      child: Text("Cancel Ride",style: TextStyle(fontSize: 12.0),textAlign: TextAlign.center,)
                    )
                  ],
                ),
              ),
            ),
          ),

          //display assign driver info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius:  BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7,0.7),
                  ),
                ],
              ),
              height:driverDetailsContainersHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height:6.0),
                    Center(child:Text((rideStatus!=null)?rideStatus+"- 4 mins":"Coming -0 mins", textAlign: TextAlign.center,style: TextStyle(fontSize: 20.0,fontFamily: "Brand Bolt"),),),
                    SizedBox(height: 22.0,),
                    const Divider(height:2.0,thickness: 2.0,),
                    const SizedBox(height:10.0),
                    Center(
                      child:Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text((carDetailDriver!=null)?carDetailDriver: "Black, Toyota Yaris \nWX7803",style:TextStyle(fontSize: 15.0,)),
                          Text((driverName!=null)?driverName.toUpperCase(): "Muhammad Salman",style:TextStyle(fontSize: 20.0,)),
                        ],
                      ),
                    ),
                      const SizedBox(height: 22.0),
                      const Divider(height:2.0,thickness: 2.0,),
                      const SizedBox(height:22.0),
                     Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(20)
                         ),
                         child:Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding:EdgeInsets.symmetric(horizontal: 20.0),
                            child: RaisedButton(
                              onPressed: ()async{
                               launch(('tel://${driverPhone}'));
                              },
                              color:Color(0xff00ACA4),
                              child: Padding(
                                padding: EdgeInsets.all(17.0),
                                child:Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: const [
                                    Icon(Icons.call,color:Colors.white,size: 26.0,),
                                    Text('Call Driver',style:TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white)),
                                   ],
                                )
                              ),
                            ),
                          )
                        ],
                      )),
                    ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection()async{

    var initialPos =Provider.of<AppData>(context,listen: false).pickUpLocation;
    var finalPos= Provider.of<AppData>(context,listen: false).dropOffLocation;

    var pickUpLatlng=LatLng(initialPos!.latitude!,initialPos.longitude!);
    var dropOffLatlng=LatLng(finalPos!.latitude!,finalPos.longitude!);

    //show progress dialogue
    showDialog(
      context: context,
      builder: (BuildContext context)=>ProgressDialog(message: "Please Wait...")
    );
    print("this is encoding here");
    var details=await AssistantMethods.obtainPlaceDirectionDetail(pickUpLatlng, dropOffLatlng);
    setState(() {
       tripDirectionDetails=details;
    });

    Navigator.pop(context);

    print("this is encoded points :: ");
    print(details.encodedPoint);

    PolylinePoints polylinePoints=PolylinePoints();
    List<PointLatLng> decodedPolylinePointResult = polylinePoints.decodePolyline(details.encodedPoint!);

    pLineCoordinates.clear();
    //setting polyline
    if(decodedPolylinePointResult.isNotEmpty){
        decodedPolylinePointResult.forEach((PointLatLng pointLatLng) {
          pLineCoordinates.add(LatLng(pointLatLng.latitude,pointLatLng.longitude));
        });
    }
    polyLineSet.clear();
      setState(() {
        Polyline polyline=Polyline(
          color:Color(0xff00ACA4),
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width:5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );
        polyLineSet.add(polyline);
      });

      LatLngBounds latLngBounds;
      if(pickUpLatlng.latitude>dropOffLatlng.latitude && pickUpLatlng.longitude > dropOffLatlng.longitude){
        latLngBounds=LatLngBounds(southwest: dropOffLatlng,northeast: pickUpLatlng);
      }
      else if(pickUpLatlng.longitude > dropOffLatlng.longitude){
        latLngBounds=LatLngBounds(southwest: LatLng(pickUpLatlng.latitude,dropOffLatlng.longitude),northeast: LatLng(dropOffLatlng.latitude,pickUpLatlng  .longitude));
      }

      else if(pickUpLatlng.latitude > dropOffLatlng.latitude){
        latLngBounds=LatLngBounds(southwest: LatLng(dropOffLatlng.latitude,pickUpLatlng.longitude),northeast: LatLng(pickUpLatlng.latitude,dropOffLatlng.longitude));
      }
      else{
        latLngBounds=LatLngBounds(southwest: pickUpLatlng,northeast: dropOffLatlng);
      }
      newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds,70));

      Marker pickUpLocMarker=Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: initialPos.placeName,snippet: "My Location"),
        position: pickUpLatlng,
        markerId: MarkerId("pickUpId")
      );

      Marker dropOffLocMarker=Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: finalPos.placeName,snippet: "DropOff Location"),
        position: dropOffLatlng,
        markerId: MarkerId("dropOffId"),
      );

    setState(() {
      markerSet.add(pickUpLocMarker);
      markerSet.add(dropOffLocMarker);
    });


      Circle pickUpLocCircle=Circle(
        fillColor: Colors.red,
        center:pickUpLatlng,
        radius: 12,
        strokeColor: Colors.black,
        circleId: CircleId("pickUpId")
      );

      Circle dropOffLocCircle=Circle(
        fillColor: Colors.lightBlueAccent,
        center:dropOffLatlng,
        radius: 12,
        strokeColor: Colors.black,
        circleId: CircleId("dropOffId")
    );

      setState(() {
        circleSet.add(pickUpLocCircle);
        circleSet.add(dropOffLocCircle);
      });
  }

  void initGeofirelistner(){
    //comment
    Geofire.initialize("availableDrivers");
    Geofire.queryAtLocation(currentPosition!.latitude, currentPosition!.longitude, 15)!.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']
        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers=NearbyAvailableDrivers();
            nearbyAvailableDrivers.key=map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude= map['longitude'];
            GeoFireAssistants.nearbyAvailableDriversList.add(nearbyAvailableDrivers);
            if(nearbyAvailableDriverKeysLoaded==true){
              updateAvailableDriversOnMap();
            }
            print('initgeofire');
            break;
          case Geofire.onKeyExited:
            GeoFireAssistants.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;
          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers=NearbyAvailableDrivers();
            nearbyAvailableDrivers.key=map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude= map['longitude'];
            GeoFireAssistants.updateDriverNearbyLocation(nearbyAvailableDrivers);
            break;
          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });

    //comment

  }

  void updateAvailableDriversOnMap(){
    setState(() {
      markerSet.clear();
    });
    Set<Marker> tMarker =Set<Marker>();
    for(NearbyAvailableDrivers driver in GeoFireAssistants.nearbyAvailableDriversList){
      LatLng driverAvailablePostion =LatLng(driver.latitude!,driver.longitude!);
      Marker marker= Marker(
        markerId: MarkerId(
          'driver${driver.key}'
        ),
        position:driverAvailablePostion,
        icon: nearByIcon!,
        rotation:AssistantMethods.createRandomNumber(360),
      );
      tMarker.add(marker);
    }
    setState(() {
      markerSet = tMarker;
    });
  }

  void craeateIconMarker(){
    if(nearByIcon==null){
      ImageConfiguration imageConfiguration=createLocalImageConfiguration(context,size:Size(3,3));
      BitmapDescriptor.fromAssetImage(imageConfiguration,"images/car.png")
      .then((value)
      {
        nearByIcon=value;
      });
    }
  }

  void noDriverFound(){
    displayToastMessage("No driver found", context);
    showDialog(
      context:context,
      barrierDismissible : false,
      builder:(BuildContext context) => NoDriverAvailableDialog(),
    );
  }

  void searchNearestDriver(){
    print("searching driver :: ");
    if(availableDrivers!.length==0){
      print("no driver found");
      displayToastMessage("there is no driver available", context);
      cancleRideRequest();
      noDriverFound();
      return;
    }
    else
    {
      var driver=availableDrivers![0];
      print("driver: ");
      print(driver.longitude);
      driversRef.child(driver.key!).child("car_details").child("ride_type").once().then((DatabaseEvent snap)async{
        if(await snap.snapshot.value !=null){
         String carType=snap.snapshot.value.toString();
         if(carType==carRideType)
         {
           print("notify driver");
           notifyDriver(driver);
           displayToastMessage("the driver is found of your type "+carRideType,context);
           availableDrivers!.removeAt(0);
         }
         else
         {
           print("your type car not avaiable");
           displayToastMessage(carRideType + " driver not available. Try again ", context);
           return;
         }
        }
        else
        {
          print("no car found");
          displayToastMessage("No available Car Found . Try again", context);
          return;
        }
      });

    }
  }

  void notifyDriver(NearbyAvailableDrivers driver){
    print("notify driver");
    driversRef.child(driver.key!).child("newRide").set(rideRiquestRef!.key);
    driversRef.child(driver.key!).child("token").once().then((DatabaseEvent snap)=> {
    if(snap.snapshot.value!=null){
       token = snap.snapshot.value.toString(),
      displayToastMessage("sending notification to driver", context),
      print("sending notification to driver"),
       AssistantMethods.sendNotificationDriver(token!, context, rideRiquestRef!.key!),
    }
    });

    var oneSecondPassed=Duration(seconds:1);
    var timer = Timer.periodic(oneSecondPassed, (timer) {
      if (state != "requesting") {
        driversRef.child(driver.key!).child("newRide").set("cancelled");
        driversRef.child(driver.key!).child("newRide").onDisconnect();
        driverRequestTimeout = 120;
        timer.cancel();
      }
      driverRequestTimeout = driverRequestTimeout - 1;
      driversRef.child(driver.key!).child("newRide").onValue.listen((event) {
        if (event.snapshot.value.toString() == "accepted") {
          driversRef.child(driver.key!).child("newRide").onDisconnect();
          driverRequestTimeout = 120;
          timer.cancel();
        }
      });
      if (driverRequestTimeout == 0) {
        driversRef.child(driver.key!).child("newRide").set("timeout");
        driversRef.child(driver.key!).child("newRide").onDisconnect();
        driverRequestTimeout = 120;
        timer.cancel();
        searchNearestDriver();
      }
    });
    }
}
