import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:soda_diop_l3gl_examen/firebase_options.dart';
import 'package:soda_diop_l3gl_examen/models/redirection_page.dart';

import 'models/home_page.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  RedirectionPage(),
    );
  }
}


