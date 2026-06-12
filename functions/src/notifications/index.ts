import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

// Make sure to initialize admin only if it hasn't been initialized yet
if (!admin.apps.length) {
  admin.initializeApp();
}

export const onNotificationCreated = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return null;
    
    const notificationData = snap.data();
    
    const userId = notificationData.userId;
    const title = notificationData.title;
    const body = notificationData.body;
    
    if (!userId || !title || !body) {
      console.log('Missing required fields, skipping.');
      return null;
    }

    // 1. Get the user's document to find their FCM Token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('User not found:', userId);
      return null;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    
    // 2. If they have notifications disabled in settings, abort
    if (userData?.notificationEnabled === false) {
      console.log('User disabled notifications globally.');
      return null;
    }

    if (!fcmToken) {
      console.log('No FCM token found for user:', userId);
      return null;
    }
    
    // 3. Construct the actual Push Notification Payload
    const message = {
      notification: {
        title: title,
        body: body,
      },
      // Pass the extra payload data so the app knows what screen to open when tapped!
      data: {
        bookingId: notificationData.payload?.bookingId || '',
        type: notificationData.type || 'system'
      },
      token: fcmToken,
    };

    // 4. Send the Push Notification via FCM
    try {
      await admin.messaging().send(message);
      console.log('Push notification sent successfully to', userId);
    } catch (error) {
      console.error('Error sending push notification:', error);
    }
    
    return null;
  });
