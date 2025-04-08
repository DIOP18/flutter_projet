import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/tache_models.dart';
import 'details_taches.dart';

class ProjectTasksScreen extends StatefulWidget {
  final String projectId;

  const ProjectTasksScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _ProjectTasksScreenState createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: Color(0xFF2C3E50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher une tâche...",
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tasks')
                  .where('projectId', isEqualTo: widget.projectId)
                  .orderBy('dueDate')
                  .snapshots()
                  .handleError((error) {
                if (error is FirebaseException && error.code == 'failed-precondition') {
                  debugPrint('🔥 ERREUR INDEX: ${error.message}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Configuration requise: ${error.message}'),
                      duration: Duration(seconds: 10),
                    ),
                  );
                }
                return Stream<QuerySnapshot>.error(error);
              }),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucune tâche trouvée'));
                }

                var filteredTasks = snapshot.data!.docs.where((doc) {
                  var task = doc.data() as Map<String, dynamic>;
                  return searchQuery.isEmpty ||
                      task['title'].toLowerCase().contains(searchQuery);
                }).toList();

                final tasks = filteredTasks.map((doc) {
                  return Task.fromMap(doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              projectId: widget.projectId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                task.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: Colors.white,
                  color: Color(0xFF2C3E50),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Échéance: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                    style: TextStyle(
                      color: task.dueDate.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    '${(task.progress * 100).toInt()}% complet',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8),

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'Urgente':
        color = Colors.red;
        break;
      case 'Haute':
        color = Colors.orange;
        break;
      case 'Moyenne':
        color = Colors.blue;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _showAddTaskDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'Moyenne';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    List<String> assignedMembers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
                title: const Text('Nouvelle Tâche', style: TextStyle(color: Color(0xFF2C3E50))),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedPriority,
                          items: ['Basse', 'Moyenne', 'Haute', 'Urgente'].map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(priority),
                            );
                          }).toList(),
                          onChanged: (value) => selectedPriority = value!,
                          decoration: const InputDecoration(
                            labelText: 'Priorité',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date limite',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                                const Spacer(),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FutureBuilder<List<DocumentSnapshot>>(
                          future: _loadProjectMembers(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final members = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assigner à:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: members.map((member) {
                                    final user = member.data() as Map<String, dynamic>;
                                    final isSelected = assignedMembers.contains(member.id);

                                    return FilterChip(
                                      label: Text(user['name'] ?? 'Membre'),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            assignedMembers.add(member.id);
                                          } else {
                                            assignedMembers.remove(member.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                TextButton(
                onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newTask = Task(
                          projectId: widget.projectId,
                          title: titleController.text,
                          description: descriptionController.text,
                          priority: selectedPriority,
                          dueDate: selectedDate,
                          createdAt: DateTime.now(),
                          status: 'À faire',
                          progress: 0.0,
                          creatorId: FirebaseAuth.instance.currentUser!.uid,
                          assignedTo: assignedMembers,
                        );

                        try {
                          // Ajout de la tâche à Firestore
                          DocumentReference docRef = await FirebaseFirestore.instance
                              .collection('tasks')
                              .add(newTask.toMap());

                          // Mise à jour de l'ID de la tâche
                          newTask.id = docRef.id;

                          // Optionnel: Mettre à jour le document avec l'ID si nécessaire
                          await docRef.update({'id': docRef.id});

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tâche créée avec succès')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2C3E50), // Couleur de fond
                      foregroundColor: Colors.white, // Couleur du texte
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Coins arrondis
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding
                    ),
                    child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
            ],
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _loadProjectMembers() async {
    final project = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    final members = List<String>.from(project['members'] ?? []);

    if (members.isEmpty) return [];

    return await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: members)
        .get()
        .then((snapshot) => snapshot.docs);
  }
}