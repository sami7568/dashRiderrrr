import 'package:dash/AllScreen/registrationScreen.dart';
import 'package:dash/AllWidgets/divider.dart';
import 'package:dash/AllWidgets/progressDialog.dart';
import 'package:dash/Models/address.dart';
import 'package:dash/Models/placePrediction.dart';
import 'package:dash/assistant/requestAssistant.dart';
import 'package:dash/dataHandler/appData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configMaps.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  TextEditingController? pickUpEditingController = TextEditingController();
  TextEditingController? dropOfEditingController = TextEditingController();
  List<PlacePredictions>? placesPredictionList=[];

  @override
  Widget build(BuildContext context) {

    String placeAddress =Provider.of<AppData>(context).pickUpLocation==null? "searching":Provider.of<AppData>(context).pickUpLocation!.placeName!;
    pickUpEditingController!.text=(placeAddress!=null)?placeAddress:"obtaining your location";
    print("This is Your Address on Search Screen ");
    print(placeAddress);

    return Scaffold(
      body: Column(
        children: [
         Container(
                  height: 180.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7,0.7)
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 25.0,right:25.0 ,bottom:20.0 ,top: 30.0),
                    child: Column(
                      children: [
                        SizedBox(height: 5.0,),
                        Stack(
                          children: [
                            GestureDetector(
                                onTap:(){
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back,)),
                            Center(
                              child: Text("Set Drop off", style: TextStyle(fontSize: 18.0,fontFamily: "Brand Bolt"),),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0,),
                        Row(
                          children: [
                            Image.asset("images/pickicon.png",height: 30,width: 20,),
                            SizedBox(width: 18.0,),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(3.0),
                                  child: TextField(
                                    controller: pickUpEditingController!,
                                    decoration: InputDecoration(
                                      hintText: "PickUp Location",
                                      fillColor:Colors.grey[400],
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom:8.0 ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0,),
                        Row(
                          children: [
                            Image.asset("images/desticon.png",height: 30,width: 20,),
                            SizedBox(width: 18.0,),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(3.0),
                                  child: TextField(
                                    onChanged: (val){
                                      findplace(val);
                                    },
                                    controller: dropOfEditingController,
                                    decoration: InputDecoration(
                                      hintText: "Where to?",
                                      fillColor:Colors.grey[400],
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom:8.0 ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
              ),
          //tile for prediction
          SizedBox(height: 0.0,),
          (placesPredictionList!.length>0)
              ?Expanded(
             child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 7.0),
                child: ListView.separated(
                  padding: EdgeInsets.all(0.0),
                  itemBuilder:(context,index){
                    return PredictionTile(placePredictions: placesPredictionList![index],);
                  },
                  separatorBuilder: (BuildContext context, int index)=> DividerWidget(),
                  itemCount: placesPredictionList!.length,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                ),
              )
          )
              :Expanded(
               child: Container(),
          ),
        ],
      ),
    );
  }

void findplace(String placeName)async
{
if(placeName.length>=1){
  String autocompleteUrl="https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890";
  var res=await RequestAssistant.getRequest(autocompleteUrl);

  if(res=="failed"){
    return;
  }
  if(res["status"]=="OK"){
    var prediction=res["predictions"];

    var placesList = (prediction as List).map((e) => PlacePredictions.fromJson(e)).toList();
    setState(() {
      placesPredictionList= placesList;
    });
  }
}
}
}


class PredictionTile extends StatelessWidget {

  final PlacePredictions? placePredictions;
  PredictionTile({Key? key,this.placePredictions}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      //padding: EdgeInsets.all(0.0),
      onPressed: (){
        getPlaceAddressDetails(placePredictions!.place_id!, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0,),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width:14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0,),
                      Text(placePredictions!.main_text!.isEmpty?"searching location":placePredictions!.main_text!,overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.0),),
                      SizedBox(height: 2.0,),
                      Text(placePredictions!.secondary_text!.isEmpty?" ":placePredictions!.secondary_text!,
                        overflow: TextOverflow.ellipsis,style: TextStyle(fontSize:12.0, color: Color(0xff515151)),),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.0,),
          ],
        ),
      ),
    );
  }


  void getPlaceAddressDetails(String placeId, context) async{

    showDialog(
        context: context,
        builder: (BuildContext context)=>ProgressDialog(message: "Setting DropOff, Please Wait..."),
    );

    String placeAddressUrl="https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    var res= await RequestAssistant.getRequest(placeAddressUrl);
    print(res);

    Navigator.pop(context);

    if(res == "failed"){
      print('result failed');

      displayToastMessage("result failed",context);
      return;
    }

    if(res["status"]=="OK"){
      Address? address=Address();
      address.placeName=res["result"]["name"];
      address.placeId=placeId;
      address.latitude=res["result"]["geometry"]["location"]["lat"];
      address.longitude=res["result"]["geometry"]["location"]["lng"];
      print('result ok');

      //displayToastMessage(address.placeName.toString(),context);

      Provider.of<AppData>(context,listen: false).updateDropOffLocationAddress(address);
      print("this is Drop Off Location:: ");
      print(address.placeName);

      Navigator.pop(context,"obtainDirection");
    }
  }
}

