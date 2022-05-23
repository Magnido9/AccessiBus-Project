import 'package:accesibus/Driver/driver.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'driver_display_screen.dart';

class DriverLogin extends StatefulWidget {
  const DriverLogin({Key? key}) : super(key: key);

  @override
  State<DriverLogin> createState() => _DriverLoginState();
}


class _DriverLoginState extends State<DriverLogin> {

  final _formkey = GlobalKey<FormState>();
  final TextEditingController _lineController = TextEditingController();
  final TextEditingController _directionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver"),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0.0,
      ),
      backgroundColor: backgroundColor,
      body: Form(
        key: _formkey,
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              const SizedBox(height: 100,),
              _buildLine(),
              _buildDirection(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.orange,
                      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))
                    ),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DriverDisplayScreen(line: _lineController.text, direction: _directionController.text, driver: DriverData(_lineController.text, _directionController.text),)));
                }, child: Text("Submit", style: TextStyle(color: textColor),)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLine(){
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        style: TextStyle(color: textColor),
        controller: _lineController,
        decoration: _buildInputDecoration("Line", Icon(Icons.directions_bus, color: buttonColor,)),
      ),
    );
  }

  Widget _buildDirection(){
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        style: TextStyle(color: textColor),
        controller: _directionController,
        decoration: _buildInputDecoration("Direction", Icon(Icons.directions, color: buttonColor,)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, Icon _icon) { // https://medium.com/zipper-studios/the-keyboard-causes-the-bottom-overflowed-error-5da150a1c660
    return InputDecoration(
        fillColor: Colors.white,
        filled: true,
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: buttonColor)),//Color.fromRGBO(252, 252, 252, 1)
        hintText: hint,
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: buttonColor)),
        hintStyle: TextStyle(color: buttonColor),
        icon: _icon,
        );
  }


}
