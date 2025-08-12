import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Cloud Messaging (FCM) notifications
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  /// Initialize Firebase Messaging
  /// 
  /// - Request permission (iOS only, Android is auto-granted)
  /// - Get FCM token and store it
  /// - Setup message handlers for different app states
  static Future<void> initialize() async {
    // Ensure Firebase is initialized
    if (!Firebase.apps.isEmpty) {
      // Request permission on iOS (Android is auto-granted)
      if (!kIsWeb) {
        final settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        debugPrint('User notification permission status: ${settings.authorizationStatus}');
      }
      
      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      
      // TODO: Store token in Firestore under user document
      // Example: FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': token});
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // TODO: Update token in Firestore
      });
      
      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Subscribe to topics
      await _messaging.subscribeToTopic('promotions');
      
      debugPrint('Firebase Messaging initialized successfully');
    } else {
      debugPrint('Firebase not initialized. Skipping notification setup.');
    }
  }
  
  /// Handle messages received while the app is in the foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    
    // TODO: Show local notification using flutter_local_notifications
    // For now, we just print the message details
  }
  
  /// Subscribe to a specific topic
  static Future<void> subscribeTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from a specific topic
  static Future<void> unsubscribeTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}

// Background message handler placeholder
// To use this, register it in main.dart before runApp() with:
// 
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   debugPrint('Background message received: ${message.messageId}');
//   // Handle background message
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   await NotificationService.initialize();
//   runApp(const MyApp());
// }
