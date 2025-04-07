import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/Firebase/Auth.dart';
import 'ProjectDetailsScreen.dart';
import 'ajout_projet_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final User? user = Auth().currentUser;
  late TabController _tabController;
  String searchQuery = "";


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        title: const Text(
          "SAMA PROJET",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Action pour le menu
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              Auth().logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "En attente"),
            Tab(text: "En cours"),
            Tab(text: "Terminés"),
            Tab(text: "Annulés"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher un projet...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProjectList(status: "En attente", searchQuery: searchQuery, tabController: _tabController),
                ProjectList(status: "En cours", searchQuery: searchQuery, tabController: _tabController),
                ProjectList(status: "Terminé", searchQuery: searchQuery, tabController: _tabController),
                ProjectList(status: "Annulé", searchQuery: searchQuery, tabController: _tabController),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _isCurrentUserAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox.shrink(); // Cache pendant le chargement
          }

          return snapshot.data == true
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AjoutProjetScreen()),
              );
            },
            backgroundColor: Color(0xFF2C3E50),
            child: Icon(Icons.add, color: Colors.white),
          )
              : SizedBox.shrink(); // Cache si non-admin
        },
      ),
    );
  }
}
Future<bool> _isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data()?['role'] == 'Admin';
}

// Fonction pour formater la date
String _formatDate(dynamic date) {
  if (date == null) return 'Non définie';

  if (date is Timestamp) {
    return DateFormat('dd/MM/yyyy').format(date.toDate());
  } else if (date is DateTime) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  return 'Date invalide';
}

// Fonction pour obtenir la couleur selon la priorité
Color _getPriorityColor(String priority) {
  switch (priority) {
    case 'Basse':
      return Colors.green;
    case 'Moyenne':
      return Colors.orange;
    case 'Haute':
      return Colors.orange;
    case 'Urgente':
      return Colors.red;
    default:
      return Colors.blue;
  }
}

// Fonction pour obtenir le Container pour afficher la priorité
Widget _getPriorityWidget(String priority) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getPriorityColor(priority).withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      priority,
      style: TextStyle(
        color: _getPriorityColor(priority),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

// Fonction pour obtenir la progression selon le statut
double _getProgressByStatus(String status) {
  switch (status) {
    case 'En attente':
      return 0.0;
    case 'En cours':
      return 0.5;
    case 'Terminé':
      return 1.0;
    case 'Annulé':
      return 0.0;
    default:
      return 0.0;
  }
}

// Contrôler l'affichage des projets dans les tabbarview
class ProjectList extends StatelessWidget {
  final String status;
  final String searchQuery;
  final TabController tabController;

  const ProjectList({
    super.key,
    required this.status,
    required this.searchQuery,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Auth().currentUser?.uid;
    if (currentUserId == null) return Center(child: Text("Veuillez vous connecter"));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('status', isEqualTo: status)
          .where('members', arrayContains: currentUserId) // Ajoutez cette ligne
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Aucun projet $status"));
        }

        var filteredProjects = snapshot.data!.docs.where((doc) {
          var project = doc.data() as Map<String, dynamic>;
          //Si le titre contient l'objet recherhcer
          return searchQuery.isEmpty || project['title'].toLowerCase().contains(searchQuery);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) {
            var doc = filteredProjects[index];
            var project = doc.data() as Map<String, dynamic>;

            // Calculer la progression en fonction du statut
            double progress = _getProgressByStatus(project['status']);

            return Card(
              elevation: 5,
              margin: EdgeInsets.only(bottom: 12),
              color: Colors.white70,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailsScreen(projectId: doc.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne du titre et de la priorité
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          _getPriorityWidget(project['priority']),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Description
                      Text(
                        project['description'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 16),

                      // Barre de progression Cela crée un clip rectangulaire aux coins arrondis.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white,
                          color: Color(0xFF2C3E50),
                          minHeight: 6,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Progression et date d'échéance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${(progress * 100).toInt()}% terminé",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                'Échéance: ${_formatDate(project['endDate'])}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Assigné à et flèche de navigation
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 12,
                            child: Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),

                      // Boutons d'actions selon le statut
                      if (status == "En attente" || status == "En cours")
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (status == "En attente")
                                ElevatedButton(
                                  onPressed: () => _updateProjectStatus(doc.id, "En cours", tabController),
                                  child: Text("Commencer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF2C3E50),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              if (status == "En cours")
                                ElevatedButton(
                                  onPressed: () => _updateProjectStatus(doc.id, "Terminé", tabController),
                                  child: Text("Terminer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              if (status != "Annulé")
                                TextButton(
                                  onPressed: () => _updateProjectStatus(doc.id, "Annulé", tabController),
                                  child: Text("Annuler", style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateProjectStatus(String projectId, String newStatus, TabController tabController) {
    // Calculer la nouvelle progression en fonction du nouveau statut
    double newProgress = _getProgressByStatus(newStatus) * 100;

    FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'status': newStatus,
      'progress': newProgress,
    }).then((_) {
      // Changer l'onglet actif en fonction du nouveau statut
      if (newStatus == "En attente") {
        tabController.animateTo(0);
      } else if (newStatus == "En cours") {
        tabController.animateTo(1);
      } else if (newStatus == "Terminé") {
        tabController.animateTo(2);
      } else if (newStatus == "Annulé") {
        tabController.animateTo(3);
      }
    });
  }
}