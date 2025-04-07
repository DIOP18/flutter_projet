import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectMembersScreen extends StatefulWidget {
  final String projectId;

  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color _primaryColor = const Color(0xFF2C3E50);
  final Color _accentColor = Colors.amber[700]!;

  Future<bool> _isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['role'] == 'Admin';
  }

  Widget _buildRoleDropdown(String userId, String currentRole, {required bool disabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentRole,
          icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
          elevation: 2,
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
          items: ['Membre', 'Chef de projet','Admin'].map((String role) {
            return DropdownMenuItem(
              value: role,
              child: Text(
                role,
                style: TextStyle(
                  color: role == 'Chef de projet' ? _accentColor : _primaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newRole) async {
            if (newRole != null) {
              await _updateUserRole(userId, newRole);
            }
          },
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rôle mis à jour avec succès'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildMemberTile(DocumentSnapshot userDoc, bool isAdmin) {
    final user = userDoc.data() as Map<String, dynamic>;
    final isCurrentUser = userDoc.id == _auth.currentUser?.uid;
    final bool isChef = user['role'] == 'Chef de projet';
    final bool isCreator = user['email'] == 'saphiafall@gmail.com';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _primaryColor.withOpacity(0.2),
          child: Icon(Icons.person, color: _primaryColor),
        ),
        title: Text(
          user['name'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isCreator
                ? Colors.black
                : (isChef ? _accentColor : _primaryColor),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'], style: TextStyle(color: Colors.grey[600])),
            if (isCreator)
              Chip(
                label: Text('Créateur du projet', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.purple.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
          ],
        ),
        trailing: isCurrentUser
            ? Chip(
          label: Text('Vous', style: TextStyle(color: Colors.white)),
          backgroundColor: _primaryColor,
        )
            : isCreator
            ? null
            : FutureBuilder<bool>(
          future: _hasAdminInProject(),
          builder: (context, adminSnapshot) {
            if (!adminSnapshot.hasData) return SizedBox.shrink();

            final hasAdmin = adminSnapshot.data!;
            final isTargetMember = user['role'] == 'Membre';
            final shouldShowControls = isAdmin
                || (isChef && isTargetMember && !hasAdmin);

            return shouldShowControls
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  _buildRoleDropdown(
                      userDoc.id,
                      user['role'] ?? 'Membre',
                      disabled: isCreator
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                  onPressed: () => _confirmRemoveMember(userDoc.id, user['name']),
                ),
              ],
            )
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Section d'ajout de membre - Visible pour Admins ET Chefs de projet
            FutureBuilder<Map<String, dynamic>>(
              future: _getCurrentUserRole(), // Nouvelle méthode
              builder: (context, roleSnapshot) {
                if (!roleSnapshot.hasData) {
                  return SizedBox.shrink();
                }

                final isAdmin = roleSnapshot.data!['isAdmin'];
                final isChef = roleSnapshot.data!['isChef'];

                return (isAdmin || isChef)
                    ? Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter un membre',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email du membre',
                            labelStyle: TextStyle(color: _primaryColor),
                            prefixIcon: Icon(Icons.email, color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isLoading ? null : _addMember,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Ajouter le membre',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
            // Liste des membres
            Expanded(
              child: FutureBuilder<bool>(
                future: _isCurrentUserAdmin(),
                builder: (context, adminSnapshot) {
                  if (!adminSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: _primaryColor));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _getProjectMembersStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: _primaryColor));
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucun membre dans ce projet',
                            style: TextStyle(color: _primaryColor),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildMemberTile(
                            snapshot.data!.docs[index],
                            adminSnapshot.data!,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<Map<String, dynamic>> _getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return {'isAdmin': false, 'isChef': false};

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return {
      'isAdmin': userDoc.data()?['role'] == 'Admin',
      'isChef': userDoc.data()?['role'] == 'Chef de projet',
    };
  }

  Stream<QuerySnapshot> _getProjectMembersStream() {
    return _firestore.collection('projects')
        .doc(widget.projectId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
      final members = List<String>.from(projectSnapshot['members'] ?? []);
      return await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: members)
          .get();
    });
  }
  Future<bool> _hasAdminInProject() async {
    final project = await _firestore.collection('projects').doc(widget.projectId).get();
    final members = List<String>.from(project['members'] ?? []);

    final users = await _firestore.collection('users')
        .where(FieldPath.documentId, whereIn: members)
        .get();

    return users.docs.any((doc) => doc['role'] == 'Admin');
  }

  void _confirmRemoveMember(String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Supprimer $userName du projet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMember(userId);
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final usersSnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'Membre')
          .get();

      if (usersSnapshot.docs.isEmpty) {
        throw Exception('Aucun utilisateur "Membre" trouvé avec cet email');
      }

      final userId = usersSnapshot.docs.first.id;
      final project = await _firestore.collection('projects').doc(widget.projectId).get();
      final currentMembers = List<String>.from(project['members'] ?? []);

      if (currentMembers.contains(userId)) {
        throw Exception('Cet utilisateur est déjà membre du projet');
      }

      await _firestore.collection('projects').doc(widget.projectId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membre ajouté avec succès'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String userId) async {
    await _firestore.collection('projects').doc(widget.projectId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membre retiré du projet'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}