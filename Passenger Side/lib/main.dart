
import 'dart:ui';
import 'login.dart';
import 'package:accesibus/Components/Appbar.dart';
import 'package:accesibus/Components/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:audioplayers/audioplayers.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccessiBus',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.light,
          fontFamily: 'Noto Serif',
          textTheme: TextTheme(
              headline1: TextStyle(color:Colors.brown,fontSize: 26.0, fontWeight: FontWeight.bold),
              headline2: TextStyle(color:Colors.brown,fontSize: 26.0, fontWeight: FontWeight.bold),
          )
      ),
      home: Login(),
    );
  }
}

class BlindPage extends StatefulWidget {
  const BlindPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<BlindPage> createState() => _BlindPageState();
}

class _BlindPageState extends State<BlindPage> {
  Timer? timer;
  var cur_station;
  TextEditingController lineController = new TextEditingController();
  bool notified=false;

  @override
  void initState() {
    super.initState();
  }
  FirebaseDatabase database = FirebaseDatabase.instance;

  Future _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
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
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AccessAppBar(
        context,
        Text(widget.title),
        GestureDetector(child:Icon(Icons.help) ,onTap:(){
          AudioPlayer audioPlayer = AudioPlayer();
          audioPlayer.setUrl('https://firebasestorage.googleapis.com/v0/b/accessibus-8e296.appspot.com/o/To%20Begin%2C%20please%20insert%20your%20desired%20line%20number%20below%2C%20and%20then%20press%20submit..mp3?alt=media&token=bcbd8541-fa4b-40b0-a14a-6f3140031623');
          audioPlayer.play('https://firebasestorage.googleapis.com/v0/b/accessibus-8e296.appspot.com/o/To%20Begin%2C%20please%20insert%20your%20desired%20line%20number%20below%2C%20and%20then%20press%20submit..mp3?alt=media&token=bcbd8541-fa4b-40b0-a14a-6f3140031623');

          //
        })
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('Insert your bus line number and press submit',style:  Theme.of(context).textTheme.headline1,textAlign: TextAlign.center),
            Container(
            margin: EdgeInsets.symmetric(horizontal: 50),
            child: TextFormField(
            keyboardType: TextInputType.number,
            controller:
            lineController,
            decoration:  InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                hintStyle: TextStyle(color: Colors.brown),
                hintText: "What line do I need?",
                fillColor: Colors.transparent),
          )),
            TextButton(
                style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    )
                ),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.brown)
            ),
                child: Container(child:Center(child:Text('Submit',style: TextStyle(
                    color: Colors.white
                ),)),width: MediaQuery.of(context).size.width*0.7,height:50),
                onPressed:    () async {
                  Position position = await _getGeoLocationPosition();
                  var location ='Latitude: ${position.latitude} , Longitude: ${position.longitude}';

                  var stationsDB= await FirebaseFirestore.instance.collection("versions").doc("v1");
                  var stations = (await stationsDB.collection("stops").get());
                  double min_dist=10000000;
                  var dist =0;
                  var min_stop;
                  double min_lat=0;
                  double min_lon=0;
                  var cur_city='';

                  stations.docs.forEach((element) {
                      var lat1=element.get('stop_lat');
                      var long1=element.get('stop_lon');
                      var lat2=position.latitude;
                      var long2=position.longitude;
                      var dist= acos((sin(lat1) * sin(lat2)) + cos(lat1) * cos(lat2) * cos(long2-long1));
                      if(dist<min_dist){
                        min_dist=dist;
                        min_lon=element.get('stop_lon');
                        min_lat=element.get('stop_lat');
                        cur_station=element.get('stop_name');
                        cur_city=element.get('city');
                        cur_station=element.id;
                        min_stop=element;
                      }});
             print(cur_station);
             print(lineController.text.trim());
             var line =lineController.text.trim();
              final snapshot = await database.ref().child('stations/$cur_station/$line').get();
                  var last;
                  if (snapshot.exists) {
                    last=snapshot.value;
                    if(last.containsKey('passengers'))
                      last['passengers']+=1;
                    else
                      last['passengers']=1;
                   } else {
                    last={};
                    print('No data available.');
                    last['passengers']=1;
                    last['arrived']=false;
                    last['nearest_bus_id']=111;
                  }
                  Map<String,Object?> a={"$line":last};
                  await database.ref().child('stations/$cur_station').update(a);
                  Navigator.push(context,MaterialPageRoute(builder: (context)=>WaitingPage(station: cur_station, line: line)));
                }
            )
          ],
        ),
      ),
    );
  }
}



class WaitingPage extends StatefulWidget {
  const WaitingPage({Key? key, required this.station, required this.line}) : super(key: key);

  final String station;
  final String line;

  @override
  State<WaitingPage> createState() => _WaitingPageState(station,line);
}

class _WaitingPageState extends State<WaitingPage> {
  var cur_station;
  var line;
  _WaitingPageState(stat,lin){
    cur_station=stat;
    line=lin;
  }
  Timer? timer;
  Timer? timer2;
  TextEditingController lineController = new TextEditingController();
  bool notified=false;
  bool arrivo=false;
  var ETA=20;
  void pol () async{
    var snapshot = await database.ref().child('API/ETA').get();
    if(snapshot.exists){
      var last =snapshot.value;
      ETA=last as int;
    }
    setState(() {

    });
    if(ETA<=2 && !notified){
      bool canVibrate = await Vibrate.canVibrate;
      Vibrate.vibrate();
      final Iterable<Duration> pauses = [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1000),
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1000),
        const Duration(milliseconds: 500),
      ];
      Vibrate.vibrateWithPauses(pauses);
      notified=true;

    }
    if(ETA<2){
      var snapshot_passengers = await database.ref().child('stations/$cur_station/$line/passengers').get();
      var snapshot_arrived = await database.ref().child('stations/$cur_station/$line/arrived').get();
      var latest=snapshot_arrived.value;
      if(snapshot_arrived.exists){
        if(snapshot_arrived.value==true){
          if(!arrivo) {
            final Iterable<Duration> pauses = [
              const Duration(milliseconds: 100),
              const Duration(milliseconds: 100),
            ];
            Vibrate.vibrateWithPauses(pauses);
            arrivo = true;
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Scaffold(
                  backgroundColor: Colors.green,
                  body: Center(
                      child: Text("Waiting for line $line", style: Theme
                          .of(context)
                          .textTheme
                          .headline1))
              );
            }

            )
            );
          }
          int a=snapshot_passengers.value as int;
          if(a==0){
            await database.ref().child('stations/$cur_station/$line').remove();
          }
          else{await database.ref().child('stations/$cur_station/$line').update( {'passengers':a-1});}
        }
      }
    }
  }
  @override
  void initState() {
    pol();
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => pol());
  }
  FirebaseDatabase database = FirebaseDatabase.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AccessAppBar(
          context,
          Text(''),
          Icon(Icons.help)
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('Waiting for bus number $line',style:  Theme.of(context).textTheme.headline1),
            Text('Minutes Until The Bus Arrives $ETA',style:  Theme.of(context).textTheme.headline1),
          ],
        ),
      ),
    );
  }
}
