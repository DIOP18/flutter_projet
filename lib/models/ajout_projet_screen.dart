import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AjoutProjetScreen extends StatefulWidget {
  @override
  _AjoutProjetScreenState createState() => _AjoutProjetScreenState();
}

class _AjoutProjetScreenState extends State<AjoutProjetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _priority = "Moyenne";

  Future<void> _ajouterProjet() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('projects').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'startDate': _startDate,
        'endDate': _endDate,
        'priority': _priority,
        'status': 'En attente',
        'progress': 0,
      });
   //retour a la page précédente
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        title: Text(
          "CREER un projet",
          style: GoogleFonts.bebasNeue(
              fontSize: 40,
              color: Colors.white
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.business, size: 100, color: Color(0xFF2C3E50)),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Titre du projet",
                        prefixIcon: Icon(Icons.title, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                    ),
                    SizedBox(height: 10),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.subject, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
                    ),

                    SizedBox(height: 10),

                    DropdownButtonFormField(
                      value: _priority,
                      items: ["Basse", "Moyenne", "Haute", "Urgente"].map((String value) {
                        return DropdownMenuItem(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _priority = value.toString();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Priorité",
                        prefixIcon: Icon(Icons.priority_high, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _dateDebutController,
                      decoration: InputDecoration(
                        labelText: "Date Debut",
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _startDate = pickedDate;
                            _dateDebutController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                      validator: (value) => value!.isEmpty ? "date obligatoire" : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _dateFinController,
                      decoration: InputDecoration(
                        labelText: "Date Fin",
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _endDate = pickedDate;
                            _dateFinController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                      validator: (value) => value!.isEmpty ? "Date obligatoire" : null,
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                        backgroundColor: const Color(0xFF2C3E50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _ajouterProjet,
                      child: Text(
                        "Creer le Projet",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 17
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}