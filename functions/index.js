// OPTIONAL: server-side reminders.
//
// Firebase does not send a notification for every due date automatically.
// This scheduled function checks once an hour for unfinished tasks due within
// the next 24 hours and sends a push notification (Firebase Cloud Messaging)
// to the owner's registered devices. Each task is reminded only once
// (the app resets `reminderSent` to false whenever the task is edited).
//
// Scheduled functions require the Firebase Blaze (pay-as-you-go) plan.
// The app works fully without this function.

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const INVALID_TOKEN_CODES = [
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
];

exports.sendDueReminders = onSchedule('every 60 minutes', async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const soon = Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);

  // Range filter on a single field: no composite index required.
  const snapshot = await db
    .collection('tasks')
    .where('dueDate', '>', now)
    .where('dueDate', '<=', soon)
    .get();

  for (const doc of snapshot.docs) {
    const task = doc.data();
    if (task.isCompleted === true || task.reminderSent === true) continue;

    const userRef = db.collection('users').doc(task.userId);
    const userDoc = await userRef.get();
    const tokens = (userDoc.data() || {}).fcmTokens || [];
    if (tokens.length === 0) continue;

    const result = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: 'Task due soon',
        body: `"${task.title}" is due within 24 hours.`,
      },
    });

    // Clean up tokens of uninstalled apps.
    const invalid = [];
    result.responses.forEach((r, i) => {
      if (!r.success && r.error && INVALID_TOKEN_CODES.includes(r.error.code)) {
        invalid.push(tokens[i]);
      }
    });
    if (invalid.length > 0) {
      await userRef.update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
    }

    await doc.ref.update({ reminderSent: true });
  }
});
