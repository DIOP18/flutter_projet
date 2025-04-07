import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/Firebase/Auth.dart';

import 'MiseAJourMDP.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _secharge = false;
  bool _login = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECECEC), Color(0xFFDADADA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(Icons.business_center, size: 90, color: Color(0xFF2C3E50)),
                const SizedBox(height: 20),
                Text("SAMA PROJET",
                  style: GoogleFonts.bebasNeue(
                    fontSize: 52,
                  ),

                ),
                const SizedBox(height: 1),
                const Text(
                  'Connectez vous pour continuer',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.70),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),

                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _login ? "Connexion" : "Inscription",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34495E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if(!_login)
                          _buildTextField(
                            controller: _nameController,
                            label: "Nom Complet",
                            icon: Icons.person,
                            keyboardType: TextInputType.emailAddress,

                          ),
                        const SizedBox(height: 10),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: "Adresse Email",
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,

                        ),

                        const SizedBox(height: 10),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: "Mot de passe",
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 5),

                        //MOTS DE PASSE OUBLIEE
                        if (_login)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context){
                                    return const OublierMDPPAGE();
                                  },
                                ),

                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 9.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Mot de passe oublié ?",
                                    style: TextStyle(color:Colors.blueAccent, fontWeight: FontWeight.bold ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),
                        if (!_login)
                          _buildTextField(
                            controller: _passwordConfirmController,
                            label: "Confirmer le mot de passe",
                            icon: Icons.lock,
                            obscureText: true,
                          ),
                        if (!_login)
                          const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2C3E50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _secharge
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _secharge = true);
                                try {
                                  if (_login) {
                                    await Auth().loginWithEmailAndPassword(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                  } else {
                                    await Auth().createUserWithEmailAndPassword(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      name: _nameController.text,
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? "Erreur")),
                                  );
                                }
                                setState(() => _secharge = false);
                              }
                            },
                            child: _secharge
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              _login ? "Se connecter" : "S'inscrire",
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                _login
                                 ? "Vous n'avez pas de compte ? "
                                  : "Vous avez déjà un compte ? ",
                             style: TextStyle(fontWeight: FontWeight.bold),

                            ),
                            GestureDetector(
                              onTap: () {
                                _formKey.currentState?.reset(); // Réinitialiser le formulaire
                                _emailController.clear();
                                _passwordController.clear();
                                _passwordConfirmController.clear();
                                setState(() => _login = !_login);
                              },
                              child: Text(
                                _login
                                    ? "S'inscrire"
                                    : "Se connecter",
                                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueAccent),
                              ),


                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Color iconColor = const Color(0xFF2C3E50), // Ajout d'un paramètre pour la couleur de l'icône
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),  // Applique la couleur spécifique
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) return "$label obligatoire";
        if (label.contains("Mot de passe") && value.length < 6) {
          return "Le mot de passe doit contenir au moins 6 caractères";
        }
        if (label == "Confirmer le mot de passe" && value != _passwordController.text) {
          return "Les mots de passe ne correspondent pas!";
        }
        return null;
      },
    );
  }

}