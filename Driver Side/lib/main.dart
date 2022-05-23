import 'package:accesibus/Components/Appbar.dart';
import 'package:accesibus/Driver/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_vibrate/flutter_vibrate.dart';


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
        brightness: Brightness.dark,
        textTheme: TextTheme(
            headline1: TextStyle(fontSize: 200.0 , fontWeight:FontWeight.w800 ),
            headline2: TextStyle(fontSize: 20.0 , fontWeight:FontWeight.w600 ),
            headline3: TextStyle(fontSize: 100.0 , fontWeight:FontWeight.w800 )
        )
      ),
      home: const DriverLogin() //const BlindPage(title: 'AccessiBus'),
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
  void  pol () async{

    var line =lineController.text.trim();
    var snapshot = await database.ref().child('API/ETA').get();
    var ETA=1111;
    if(snapshot.exists){
      var last =snapshot.value;
      ETA=last as int;
     }
    snapshot = await database.ref().child('API/nearest_bus_id').get();
    if(snapshot.exists){
      var last =snapshot.value;
    }
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

// vibrate - sleep 0.5s - vibrate - sleep 1s - vibrate - sleep 0.5s - vibrate
      Vibrate.vibrateWithPauses(pauses);
      notified=true;

    }
    if(ETA<2){
        var snapshot_passengers = await database.ref().child('stations/$cur_station/$line/passengers').get();
        var snapshot_arrived = await database.ref().child('stations/$cur_station/$line/arrived').get();
        print('aaa');
        print(snapshot_arrived.value);
        var latest=snapshot_arrived.value;
        var ETA=1111;
        if(snapshot_arrived.exists){
          if(snapshot_arrived.value==true){
            print('assad');
            print(snapshot_passengers.value);
            int a=snapshot_passengers.value as int;
            if(a==0){
              await database.ref().child('stations/$cur_station/$line').remove();
            }
            else{await database.ref().child('stations/$cur_station/$line').update( {'passengers':a-1});}

          }
          print(snapshot_arrived.value);
      }
    }
  }
  @override
  void initState() {

    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => pol());

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
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AccessAppBar(
        context,
        Text(widget.title),
        Icon(Icons.logout)
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Insert your line and press send'),
            Container(
        margin: EdgeInsets.symmetric(
            horizontal: 50),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller:
            lineController,
            decoration:  InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                hintStyle: TextStyle(color: Colors.grey[800]),
                hintText: "What line do I need?",
                fillColor: Colors.transparent),
          )),
             MaterialButton(
                color: Colors.blue,
                child: Text('Submit Current Station'),
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

                  //   }
                  // }
                  final snapshot = await database.ref().child('stations/$cur_station/$line').get();
                  var last;

                  print('aaaa');
                  if (snapshot.exists) {
                    print('assa');
                    print(snapshot.value);
                    last=snapshot.value;
                    print(last);
                    last['passengers']+=1;
                    print(last);
                  } else {
                    last={};
                    print('No data available.');
                    last['passengers']=1;
                    last['arrived']=true;
                    last['nearest_bus_id']=111;
                  }
                  print(last);
                  Map<String,Object?> a={"$line":last};
                  await database.ref().child('stations/$cur_station').update(a);
                  print(cur_station);
                  setState(() {

                  });
                }
            )
          ],
        ),
      ),
    );
  }
}
