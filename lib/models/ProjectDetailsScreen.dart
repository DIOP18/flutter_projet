import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'FichiersTab.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: Text("Détails du Projet", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Aperçu"),
            Tab(text: "Tâches"),
            Tab(text: "Membres"),
            Tab(text: "Fichiers"),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var project = snapshot.data!.data() as Map<String, dynamic>;
          final status = project['status'] ?? "En attente";
          final progress = _getProgressByStatus(status);

          return TabBarView(
            controller: _tabController,
            children: [
              // Onglet Aperçu
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête du projet
                    Center(
                      child: Text(
                        project['title'] ?? "Sans titre",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Carte d'information principale
                    Card(
                      elevation: 5,
                      color: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statut et Priorité
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    status,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: _getStatusColor(status),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                _getPriorityWidget(project['priority']),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Description
                            Text(
                              "Description",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              project['description'] ?? "Aucune description",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),

                            // Dates
                            Text(
                              "Dates",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50)),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  "Début: ${_formatDate(project['startDate'])}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  "Fin: ${_formatDate(project['endDate'])}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Section Avancement
                    Center(
                      child: Text(
                        "Avancement du projet",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50)),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          color: Color(0xFF2C3E50),
                          strokeWidth: 15,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Section Changer le statut
                    Center(
                      child: Text(
                        "Changer le statut du projet",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50)),
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusButton("En attente", status),
                        _buildStatusButton("En cours", status),
                        _buildStatusButton("Terminé", status),
                        _buildStatusButton("Annulé", status),
                      ],
                    ),
                  ],
                ),
              ),

              // Placeholders pour les autres onglets
              Center(child: Text("Tâches - À implémenter")),
              Center(child: Text("Membres - À implémenter")),
              ProjectFilesTab(projectId: widget.projectId),
            ],
          );
        },
      ),
    );
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

  // Widget pour afficher la priorité
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

  // Couleur selon le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente': return Colors.orange;
      case 'En cours': return Colors.blue;
      case 'Terminé': return Colors.green;
      case 'Annulé': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Bouton pour changer le statut
  Widget _buildStatusButton(String status, String currentStatus) {
    return ElevatedButton(
      onPressed: () {
        _updateProjectStatus(status);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: currentStatus == status
            ? _getStatusColor(status)
            : _getStatusColor(status).withOpacity(0.2),
        foregroundColor: currentStatus == status ? Colors.white : _getStatusColor(status),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(status),
    );
  }

  // Mettre à jour le statut dans Firestore
  Future<void> _updateProjectStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .update({
      'status': newStatus,
      'progress': _getProgressByStatus(newStatus) * 100,
    });
  }
}