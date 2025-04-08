import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  late final String? id; // Nullable car peut être généré par Firestore
  final String projectId;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final DateTime createdAt;
  final String status;
  late final double progress;
  final String creatorId;
  final List<String> assignedTo;
  List<TaskComment> comments;

  Task({
    this.id, // ID optionnel
    required this.projectId,
    required this.title,
    this.description = '',
    this.priority = 'Moyenne',
    required this.dueDate,
    required this.createdAt,
    this.status = 'À faire',
    this.progress = 0.0,
    required this.creatorId,
    required this.assignedTo,
    this.comments = const [],
  });

  factory Task.fromMap(Map<String, dynamic> map, {String? id}) {
    try {
      return Task(
        id: id ?? map['id'], // Priorité à l'ID fourni en paramètre
        projectId: map['projectId'] ?? '',
        title: map['title'] ?? 'Sans titre',
        description: map['description'] ?? '',
        priority: _validatePriority(map['priority']),
        dueDate: _parseTimestamp(map['dueDate']),
        createdAt: _parseTimestamp(map['createdAt'], fallback: DateTime.now()),
        status: _validateStatus(map['status']),
        progress: _parseProgress(map['progress']),
        creatorId: map['creatorId'] ?? '',
        assignedTo: List<String>.from(map['assignedTo'] ?? []),
        comments: _parseComments(map['comments']),
      );
    } catch (e) {
      print('Erreur Task.fromMap: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'progress': progress,
      'creatorId': creatorId,
      'assignedTo': assignedTo,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  // Méthodes helper inchangées...
  static String _validatePriority(String? priority) {
    const validPriorities = ['Basse', 'Moyenne', 'Haute', 'Urgente'];
    return (priority != null && validPriorities.contains(priority))
        ? priority
        : 'Moyenne'; // Valeur par défaut
  }

  static String _validateStatus(String? status) {
    const validStatuses = ['À faire', 'En cours', 'Terminé'];
    return (status != null && validStatuses.contains(status))
        ? status
        : 'À faire'; // Valeur par défaut
  }

  static double _parseProgress(dynamic progress) {
    try {
      final value = double.tryParse(progress.toString()) ?? 0.0;
      return value.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp, {DateTime? fallback}) {
    try {
      return (timestamp as Timestamp).toDate();
    } catch (e) {
      return fallback ?? DateTime.now(); // Fallback sécurisé
    }
  }

  static List<TaskComment> _parseComments(dynamic commentsData) {
    if (commentsData == null) return [];

    try {
      return (commentsData as List).map((comment) {
        if (comment is Map<String, dynamic>) {
          return TaskComment.fromMap(comment);
        }
        return TaskComment;
      }).whereType<TaskComment>().toList(); // Filtre les nulls
    } catch (e) {
      print('Erreur de parsing des commentaires: $e');
      return [];
    }
  }
}

class TaskComment {
  late final String? id; // Nullable
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;

  TaskComment({
    this.id,
    required this.userId,
    this.userName = '',
    required this.content,
    required this.timestamp,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map, {String? id}) {
    return TaskComment(
      id: id ?? map['id'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}