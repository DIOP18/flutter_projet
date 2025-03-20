import 'package:firebase_auth/firebase_auth.dart';
import'package:flutter/material.dart';
class OublierMDPPAGE extends StatefulWidget {
  const OublierMDPPAGE({super.key});

  @override
  State<OublierMDPPAGE> createState() => _OublierMDPPAGEState();
}

class _OublierMDPPAGEState extends State<OublierMDPPAGE> {
  final TextEditingController _emailController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  Future passWordChange() async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email:_emailController.text.trim());
      showDialog(
          context: context,
          builder: (context){
            return const AlertDialog(
              content: Text("Lien envoyé! Consultez votre Email"),
            );
          }
      );
    }on FirebaseAuthException catch(e){
      print(e);
      showDialog(
          context: context,
          builder: (context){
        return AlertDialog(
          content: Text(e.message.toString()),
        );
          }
      );
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,

      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
              "Recupération de mots de passe via email",
            style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextField(
              controller:_emailController ,
              decoration: InputDecoration(
                enabledBorder:OutlineInputBorder(
                  borderSide: const BorderSide(color:Color(0xFF2C3E50)),
                  borderRadius: BorderRadius.circular(12),
                ),
               focusedBorder: OutlineInputBorder(
                 borderSide: const BorderSide(color:Color(0xFF2C3E50)),
                 borderRadius: BorderRadius.circular(12),

               ),
               hintText: "Email",
                fillColor: Colors.white,
                filled: true,
              ),

            ),
          ),
          const SizedBox(height: 15),
          MaterialButton(
            onPressed: passWordChange,
            color: const Color(0xFF2C3E50),
            child: const Text(
              "ENVOYER",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),

          ),
        ],

      ),

    );
  }
}
