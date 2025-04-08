// screens/task_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/tache_models.dart';

class TaskDetailScreen extends StatefulWidget {
  final String projectId;
  final Task task;

  const TaskDetailScreen({
    Key? key,
    required this.projectId,
    required this.task,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isCommenting = false;

  // Couleur thème principale
  final Color _primaryColor = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Partie principale défilable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressSlider(widget.task.progress),
                  SizedBox(height: 20),
                  _buildAssignedMembers(widget.task.assignedTo),
                  SizedBox(height: 20),
                  _buildTaskDescription(widget.task.description),
                  SizedBox(height: 24),
                  _buildCommentsSection(),
                  // Espace supplémentaire en bas pour éviter que le dernier commentaire soit caché
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Champ de commentaire fixé en bas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildCommentInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progression:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _primaryColor,
                  thumbColor: _primaryColor,
                  overlayColor: _primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: widget.task.progress,
                  onChanged: (value) {
                    setState(() {
                      widget.task.progress = value;
                    });
                    _updateTaskProgress(value);
                  },
                  label: '${(widget.task.progress * 100).toInt()}%',
                ),
              ),
            ),
            Text('${(widget.task.progress * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedMembers(List<String> assignedTo) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getAssignedUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(
            color: Color(0xFF2C3E50),
          );
        }

        final users = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigné à:',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: users.map((user) {
                try {
                  final userData = user.data() as Map<String, dynamic>;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(0xFF2C3E50),
                      backgroundImage: NetworkImage(userData['photoUrl'] ?? ''),
                      onBackgroundImageError: (_, __) {},
                      child: userData['photoUrl'] == null
                          ? Text(userData['name']?.isNotEmpty ?? false
                          ? userData['name'][0].toUpperCase()
                          : '?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      )
                          : null,
                    ),
                    label: Text(userData['name'] ?? 'Membre'),
                  );
                } catch (e) {
                  return Chip( // Fallback en cas d'erreur
                    label: Text('Membre'),
                    avatar: CircleAvatar(child: Icon(Icons.person)),
                  );
                }
              }).toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildTaskDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(widget.task.description),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discussion:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tasks')
              .doc(widget.task.id)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: _primaryColor));
            }

            final comments = snapshot.data!.docs.map((doc) {
              return TaskComment.fromMap(doc.data() as Map<String, dynamic>..['id'] = doc.id);
            }).toList();

            if (comments.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  'Aucun commentaire pour le moment',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return _buildCommentItem(comments[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(TaskComment comment) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(comment.userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final user = snapshot.data!.data() as Map<String, dynamic>;
        final isCurrentUser = comment.userId == _auth.currentUser?.uid;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor,
                backgroundImage: user['photoUrl'] != null
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null
                    ? Text(
                  user['name']?[0] ?? '?',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                )
                    : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Color(0xFF2C3E50).withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'Utilisateur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser ? _primaryColor : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 4, left: 8),
                      child: Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(comment.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.send, color: _primaryColor),
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  _addComment(_commentController.text);
                  _commentController.clear();
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(String content) async {
    // Create comment without specifying an ID
    final comment = TaskComment(
      id: null, // Will be auto-generated by Firestore
      userId: _auth.currentUser!.uid,
      content: content,
      timestamp: DateTime.now(),
    );

    // Add to Firestore subcollection - Firestore will generate the ID
    final commentRef = await _firestore
        .collection('tasks')
        .doc(widget.task.id)
        .collection('comments')
        .add(comment.toMap());

    // Update the comment with the generated ID if needed
    comment.id = commentRef.id;

    // Faire défiler vers le bas après l'ajout d'un commentaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _updateTaskProgress(double progress) async {
    await _firestore
        .collection('tasks')
        .doc(widget.task.id)
        .update({'progress': progress});
  }

  Future<List<DocumentSnapshot>> _getAssignedUsers() async {
    final users = await Future.wait(
        widget.task.assignedTo.map((userId) =>
            _firestore.collection('users').doc(userId).get()
        ).toList()
    );
    return users;
  }

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.removeListener(_handleFocusChange);
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_commentFocusNode.hasFocus && !_isCommenting) {
      setState(() => _isCommenting = true);
    } else if (!_commentFocusNode.hasFocus && _isCommenting) {
      setState(() => _isCommenting = false);
    }
  }
}