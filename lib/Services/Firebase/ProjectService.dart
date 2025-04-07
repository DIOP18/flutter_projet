import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> promoteToProjectLeader(
      String projectId,
      String userId,
      ) async {
    await _firestore.collection('projects').doc(projectId).update({
      'leader': userId,
    });

    // Mise à jour du rôle dans users
    await _firestore.collection('users').doc(userId).update({
      'role': 'Chef',
    });
  }


  // Ajouter automatiquement des membres à un projet
  Future<void> addMembersToProject(
      String projectId,
      List<String> memberEmails,
      {String role = 'Membre'}
      ) async {
    try {
      final usersQuery = await _firestore.collection('users')
          .where('email', whereIn: memberEmails)
          .where('role', isEqualTo: role)
          .get();

      final memberUids = usersQuery.docs.map((doc) => doc.id).toList();

      if (memberUids.isEmpty) {
        throw Exception('Aucun utilisateur trouvé avec ces emails');
      }

      await _firestore.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion(memberUids),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout des membres: ${e.toString()}');
    }
  }

  // Nouvelle méthode pour récupérer les chefs de projet
  Stream<List<Map<String, dynamic>>> getProjectLeaders(String projectId) {
    return _firestore.collection('projects').doc(projectId).snapshots().asyncMap(
          (projectSnapshot) async {
        final leaderId = projectSnapshot['leader'];
        if (leaderId == null) return [];

        final leaderDoc = await _firestore.collection('users').doc(leaderId).get();
        return [{'uid': leaderId, ...leaderDoc.data() as Map<String, dynamic>}];
      },
    );
  }
  Stream<QuerySnapshot> getUserProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  // Récupérer tous les membres d'un projet
  Stream<List<Map<String, dynamic>>> getProjectMembers(String projectId) {
    return _firestore.collection('projects').doc(projectId).snapshots().asyncMap(
          (projectSnapshot) async {
        final members = List<String>.from(projectSnapshot['members'] ?? []);

        if (members.isEmpty) return [];

        final usersQuery = await _firestore.collection('users')
            .where(FieldPath.documentId, whereIn: members)
            .get();

        return usersQuery.docs.map((doc) {
          return {
            'uid': doc.id,
            ...doc.data(),
          };
        }).toList();
      },
    );
  }
}