import 'package:accesibus/Driver/driver.dart';
import 'package:flutter/material.dart';

class DriverDisplayScreen extends StatefulWidget {
  const DriverDisplayScreen(
      {Key? key, required this.line, required this.direction, required this.driver})
      : super(key: key);

  final line;
  final direction;
  final DriverData driver;

  @override
  State<DriverDisplayScreen> createState() => _DriverDisplayScreenState();
}

class _DriverDisplayScreenState extends State<DriverDisplayScreen> {
  // final line = widget.line;
  // final direction = widget.direction;

  var stations = ["Pika", "2", "3"];
  var numPassengers = [1, 2, 3];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<List<WaitStation>>(
          stream: widget.driver.getNextStations(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.connectionState == ConnectionState.active) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                      decoration: BoxDecoration(

                          color: Colors.amber,
                          border: Border.all(color: Colors.brown)),
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Next: ", style: Theme
                                    .of(context)
                                    .textTheme
                                    .headline2),

                              ]), Text("${snapshot.data![0].passengersCounter}",
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .headline1)

                        ],
                      )),
                  Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.4,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.brown)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width * 0.49,
                            decoration:
                            BoxDecoration(

                                color: Colors.deepOrange,
                                border: Border.all(color: Colors.brown)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("2nd station: ${snapshot.data![1]
                                    .stationId}",

                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline2),
                                Text("Number of passengers: ${snapshot.data![1]
                                    .passengersCounter}",
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline2)
                              ],
                            ),
                          ),
                          Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.49,
                              decoration:
                              BoxDecoration(
                                  color: Colors.deepOrange,
                                  border: Border.all(color: Colors.brown)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("3rd station: ${snapshot.data![2]
                                      .stationId}",
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .headline2),
                                  Text(
                                      "Number of passengers: ${snapshot.data![2]
                                          .passengersCounter}",
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .headline2)
                                ],
                              ))
                        ],
                      )),
                ],
              );
            } else {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
          }
        ));
  }
}
