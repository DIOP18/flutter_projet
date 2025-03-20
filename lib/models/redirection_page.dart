import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../Services/Firebase/Auth.dart';

import 'HomePage.dart';
import 'LoginPage.dart';


class RedirectionPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _RedirectionPageState();
  }

}

class _RedirectionPageState extends State<RedirectionPage>{
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream:Auth().authStateChanges,
        builder:(context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const CircularProgressIndicator();
          }else if(snapshot.hasData){
            return const MyHomePage();
          }else{
            return const LoginPage();
          }
        }
    );
  }
}