import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectMembersTab extends StatefulWidget {
  final String projectId;

  const ProjectMembersTab({Key? key, required this.projectId}) : super(key: key);

  @override
  _ProjectMembersTabState createState() => _ProjectMembersTabState();
}

class _ProjectMembersTabState extends State<ProjectMembersTab> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _currentUserEmail;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
  }

  Future<void> _getCurrentUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserEmail = currentUser.email;
      });

      // Récupérer le rôle de l'utilisateur actuel dans ce projet
      final projectDoc = await _firestore.collection('projects').doc(widget.projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>;
      final members = projectData['members'] as List<dynamic>;

      for (var member in members) {
        if (member['email'] == _currentUserEmail) {
          setState(() {
            _currentUserRole = member['role'];
          });
          break;
        }
      }
    }
  }

  Future<void> _addMemberByEmail() async {
    if (_emailController.text.isEmpty) return;

    // Vérifier si l'utilisateur actuel a les droits d'ajouter des membres
    if (_currentUserRole != 'admin' && _currentUserRole != 'creator') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous n\'avez pas les permissions pour ajouter des membres'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si l'email existe déjà dans le projet
      final projectDoc = await _firestore.collection('projects').doc(widget.projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>;
      final members = List<Map<String, dynamic>>.from(projectData['members'] ?? []);

      bool emailExists = false;
      for (var member in members) {
        if (member['email'] == _emailController.text.trim()) {
          emailExists = true;
          break;
        }
      }

      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cet utilisateur est déjà membre du projet'))
        );
        return;
      }

      // Vérifier si l'utilisateur existe dans Firestore
      final usersQuery = await _firestore.collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun utilisateur trouvé avec cet email'))
        );
        return;
      }

      // Ajouter le membre au projet
      final userData = usersQuery.docs.first.data();
      final newMember = {
        'email': _emailController.text.trim(),
        'displayName': userData['displayName'] ?? _emailController.text.split('@')[0],
        'role': 'member', // Rôle par défaut
        'photoURL': userData['photoURL'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('projects').doc(widget.projectId).update({
        'members': FieldValue.arrayUnion([newMember])
      });

      // Envoyer une notification à l'utilisateur ajouté (optionnel)
      await _firestore.collection('notifications').add({
        'userId': usersQuery.docs.first.id,
        'title': 'Nouveau projet',
        'message': 'Vous avez été ajouté à un nouveau projet: ${projectData['title']}',
        'projectId': widget.projectId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre ajouté avec succès'))
      );

      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMemberRole(String email, String newRole) async {
    try {
      // Récupérer les données actuelles du projet
      final projectDoc = await _firestore.collection('projects').doc(widget.projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>;
      List<dynamic> members = List<dynamic>.from(projectData['members'] ?? []);

      // Mettre à jour le rôle du membre
      for (int i = 0; i < members.length; i++) {
        if (members[i]['email'] == email) {
          members[i]['role'] = newRole;
          break;
        }
      }

      // Mettre à jour le document dans Firestore
      await _firestore.collection('projects').doc(widget.projectId).update({
        'members': members
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôle mis à jour avec succès'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'))
      );
    }
  }

  Future<void> _removeMember(String email) async {
    try {
      // Récupérer les données actuelles du projet
      final projectDoc = await _firestore.collection('projects').doc(widget.projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>;
      List<dynamic> members = List<dynamic>.from(projectData['members'] ?? []);

      // Retirer le membre de la liste
      members.removeWhere((member) => member['email'] == email);

      // Mettre à jour le document dans Firestore
      await _firestore.collection('projects').doc(widget.projectId).update({
        'members': members
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre retiré avec succès'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ d'ajout de membre par email
          if (_currentUserRole == 'admin' || _currentUserRole == 'creator')
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Ajouter un membre par email',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _addMemberByEmail,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Liste des membres
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('projects').doc(widget.projectId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Projet non trouvé'));
                }

                final projectData = snapshot.data!.data() as Map<String, dynamic>;
                final members = List<Map<String, dynamic>>.from(projectData['members'] ?? []);

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final String email = member['email'];
                    final String displayName = member['displayName'] ?? email.split('@')[0];
                    final String role = member['role'] ?? 'member';
                    final String photoURL = member['photoURL'] ?? '';
                    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

                    // Définir la couleur du rôle
                    Color roleColor;
                    switch (role) {
                      case 'creator':
                        roleColor = Colors.orange;
                        break;
                      case 'admin':
                        roleColor = Colors.blue;
                        break;
                      default:
                        roleColor = Colors.purple;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(initial),
                          backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                          child: photoURL.isEmpty ? Text(initial) : null,
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(email),
                        trailing: role == 'creator'
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: roleColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Créateur',
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                            : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              _removeMember(email);
                            } else if (['admin', 'member'].contains(value)) {
                              _updateMemberRole(email, value);
                            }
                          },
                          itemBuilder: (context) => [
                            if (role != 'admin' && (_currentUserRole == 'creator' || _currentUserRole == 'admin'))
                              const PopupMenuItem(
                                value: 'admin',
                                child: Text('Définir comme Admin'),
                              ),
                            if (role == 'admin' && _currentUserRole == 'creator')
                              const PopupMenuItem(
                                value: 'member',
                                child: Text('Définir comme Membre'),
                              ),
                            if ((role != 'creator' && _currentUserRole == 'creator') ||
                                (role == 'member' && _currentUserRole == 'admin'))
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Retirer du projet'),
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: role == 'admin' ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: role == 'member' ? Border.all(color: Colors.grey.shade300) : null,
                            ),
                            child: Text(
                              role == 'admin' ? 'Admin' : 'Membre',
                              style: TextStyle(
                                color: role == 'admin' ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String initial) {
    // Attribuer une couleur en fonction de la première lettre
    switch (initial) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.red.shade400;
      case 'M':
        return Colors.purple;
      case 'O':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}