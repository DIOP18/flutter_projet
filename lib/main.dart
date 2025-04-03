import 'package:examen_soda_diop_l3gl/models/redirection_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';



Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options:DefaultFirebaseOptions.currentPlatform
  );
  await Supabase.initialize(
    url: 'https://xvcyoqyuffmjnzathsov.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2Y3lvcXl1ZmZtam56YXRoc292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwODQyMjksImV4cCI6MjA1ODY2MDIyOX0.DkTfb1riCa7ntYrAWN8bhklMH893BmGKI5sUKGI_sIo',

  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RedirectionPage(),


    );
  }
}


