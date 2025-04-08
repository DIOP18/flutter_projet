// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  void _showNotification(RemoteMessage message) {
    // Afficher la notification locale
  }

  Future<void> sendTaskNotification({
    required String taskId,
    required String title,
    required String body,
    required List<String> recipientIds,
  }) async {
    // Envoyer la notification via FCM
  }
}