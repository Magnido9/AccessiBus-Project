
import 'dart:ui';
import 'package:accesibus/Components/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  bool IsLoading = false;
  TextEditingController dissabillityController = new TextEditingController();
  TextEditingController emailController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Enter your login details please',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )),
          Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 50),
              child: TextFormField(
                controller: emailController,
                decoration: InputDecoration(hintText: "Username"),
              )),
          Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 50),
              child: TextFormField(
                controller: passwordController,
                decoration: InputDecoration(hintText: "Password"),
              )),

          MaterialButton(
              color: Colors.green,
              child:Text('Login'),
              onPressed:() async {
                final String email = emailController.text.trim();
                final String password = passwordController.text.trim();
                setState(() => IsLoading = true);
                dynamic result = await AuthRepository.instance()
                    .signIn(email, password, context);
                print(result);
                if (result == null) {
                  setState(() => IsLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('There was an error loging into the app')));
                }
                else{
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> BlindPage(title: '')));
                }
              }),

          Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 50),
              child: TextFormField(
                controller: dissabillityController,
                decoration: InputDecoration(hintText: "Dissability"),
              )),
          MaterialButton(
              color: Colors.green,
              child:Text('Singup'),
              onPressed:() async {
                final String email = emailController.text.trim();
                final String password = passwordController.text.trim();
                final String dissabillity=dissabillityController.text.trim();
                setState(() => IsLoading = true);
                dynamic result = await AuthRepository.instance()
                    .signUp(email, password, context);
                print(result);
                if (result == null) {
                  setState(() => IsLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('There was an error loging into the app')));
                }
                else{
                  String? pid = AuthRepository.instance().user?.uid;

                  await FirebaseFirestore.instance.collection("users").add({pid.toString():{'dissabillity':dissabillity}});
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> BlindPage(title: '')));
                }
              })
        ],
      ),
    );
  }
}

