import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Services/Firebase/Auth.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {
  final User? user = Auth().currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("Accueil"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(user?.email ?? 'User Email'),
            const SizedBox(height: 20,),
            ElevatedButton(onPressed:(){
              Auth().logout();
            },
                child: const Text("Se Déconnecter")
            )

          ],
        ),

      ),
    );
  }
}