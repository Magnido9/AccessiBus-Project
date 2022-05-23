
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';


class WaitStation{
  int passengersCounter;
  String stationId;
  WaitStation(this.passengersCounter, this.stationId );



}
class DriverData {
  var ENDOFROUTE = "finished";
  int currStationidx=-1;
  var stations;
  String currStation= "";
  String direction;
  String line;
  DriverData(this.line, this.direction);
  FirebaseFirestore staticDB =  FirebaseFirestore.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;


   Stream<List<WaitStation>> getNextStations() async* {
    if(currStationidx==-1){//first time asked the curr station is -1
        currStationidx=0;
        var ref = await staticDB.collection("versions").doc("v1").collection("routes").doc(line).get();
        stations = ref[direction];
        currStation= stations[currStationidx];
        checkArrived();
    }
      while(currStationidx < stations.length) {
        List<WaitStation> results = [];
        List<String> threeNearestStation = await getNearestStations(3);
        for (var i = 0; i < threeNearestStation.length; i++) {
          var a = await getPassengersCount(threeNearestStation[i], line);
          results.add(WaitStation(
              a,
              threeNearestStation[i]));
        }
        updateETA();
        yield results;
      }
  }

   Future<List<String>> getNearestStations(int numberOfStations) async{
     List<String> res =[];

     for (var i=0; i<numberOfStations; i++){
       var len = stations.length as int;
       i=(i+currStationidx)%len;
       if(i < stations.length){
         res.add(stations[i]);
       }
       else{
         res.add(ENDOFROUTE);
       }
     }
     return res;
  }

  Future<List<String>> updateETA() async{
    List<String> res =[];

    for (var i=0; i < stations.length; i++){
      var cur_station = (await staticDB.collection("versions").doc("v1").collection("stops").doc(stations[i]).get());
      Position position = await _getGeoLocationPosition();
      var lat1=cur_station['stop_lat'];
      var long1=cur_station['stop_lon'];
      var lat2=position.latitude;
      var long2=position.longitude;
      var dist= distance(lat1, long1, lat2, long2);

      var snapshot= await database.ref().child('stations/$cur_station/$line/ETA').get();
      double ETA;
      if(snapshot.exists){
        ETA=snapshot.value as double;
        if(ETA>dist/50){
            ETA=dist/50;
        }
      }else{
        ETA=dist/50;
      }
      var stat=cur_station.id;
      await database.ref().child('stations/$stat/$line').update({'ETA':ETA});
    }
    return res;
  }

   Future<int> getPassengersCount(String stationId, String line) async {
     if(stationId == ENDOFROUTE){
       return 0;
     }

    var snapshotPassengers = await database.ref().child('stations/$stationId/$line/passengers').get();
    if(snapshotPassengers.exists){
      var numPass = snapshotPassengers.value as int;
      return numPass;
    }
    return 0; // the station is probably with out disable pass.
  }

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

  double degreeToRadian(double degree) {
    double PI = 3.141592653589793238;
    return degree * PI / 180;
  }

  double distance(double lat1, double long1, double lat2, double long2)
  {
  // Convert the latitudes
  // and longitudes
  // from degree to radians.
  lat1 = degreeToRadian(lat1);
  long1 = degreeToRadian(long1);
  lat2 = degreeToRadian(lat2);
  long2 = degreeToRadian(long2);

  // Haversine Formula
  var dlong = long2 - long1;
  var dlat = lat2 - lat1;

  var ans = pow(sin(dlat / 2), 2) +
  cos(lat1) * cos(lat2) *
  pow(sin(dlong / 2), 2);

  ans = 2 * asin(sqrt(ans));

  // Radius of Earth in
  // Kilometers, R = 6371
  // Use R = 3956 for miles
  var R = 6371;

  // Calculate the result
  ans = ans * R;

  return ans;
  }

  void checkArrived()async {
     while(true){
       sleep(Duration(seconds: 5));
       var station = (await staticDB.collection("versions").doc("v1").collection("stops").doc(currStation).get());
       Position position = await _getGeoLocationPosition();
       var lat1=station['stop_lat'];
       var long1=station['stop_lon'];
       var lat2=position.latitude;
       var long2=position.longitude;
       var dist= distance(lat1, long1, lat2, long2);
       if(dist < 0.2)
         {
           var lineRef = await database.ref().child('stations/$currStation/$line');
            lineRef.update({"arrived":true});
             currStationidx++;
             currStation= stations[currStationidx];
           }
       }
     }
}
