
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // NOTE: Make sure you paste your real OneSignal App ID here
  static const String oneSignalAppId = "6ac28531-232a-43aa-a960-d1114cab6c8a"; 

  static Future<void> initOneSignal() async {
    // Remove this method to stop OneSignal Debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(oneSignalAppId);

    // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt.       
    OneSignal.Notifications.requestPermission(true);
    
    // NOTE: You can listen for notification events here
    // For example, when a notification is clicked:
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: $event');
      // You can add navigation logic here, e.g., open a specific screen
    });
  }
}
