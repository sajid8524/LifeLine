# LifeSaver DTN

Emergency communication when traditional communication fails.

This GDG hackathon MVP keeps the original Google Nearby Connections proof working and builds an offline-first SOS workflow around it.

## What Works

- HOST / DISCOVER / CONNECT using Google Nearby Connections
- Offline SOS packet exchange using Bluetooth/BLE/Wi-Fi Direct via Nearby Connections
- EmergencyMessage JSON payloads instead of only `HELLO`
- SQLite local storage for incoming/outgoing emergencies
- Simple Store-Carry-Forward relay with `messageId + endpointId` duplicate suppression
- TTL and relay count fields
- Rescue Node mode for Firebase sync when internet returns
- Firebase Core + Firestore integration
- Google Maps emergency markers
- Gemini priority classification with offline heuristic fallback

## APK

Installable release APK:

```text
dist/lifesaver-dtn-mvp-release.apk
```

The APK is signed with the Android debug certificate for hackathon side-loading. Replace this with a private release key before production or Play Store use.

## Offline Nearby Demo

1. Install the same APK on Phone A and Phone B.
2. Turn mobile data off.
3. Disconnect internet.
4. Keep Bluetooth on.
5. Keep Wi-Fi hardware on.
6. Keep Location/GPS on.
7. Phone A: open app and tap `HOST`.
8. Phone B: open app and tap `DISCOVER`.
9. Phone B: tap `SEND SOS`, fill the form, preview, then `SEND`.
10. Phone A should store the incoming SOS in Inbox.

## Store-Carry-Forward Demo

1. Phone A creates SOS while offline.
2. Phone B connects with `DISCOVER`.
3. Phone A relays stored SOS to Phone B.
4. Phone B later connects to Phone C/Rescue Node.
5. Phone B relays stored SOS unless TTL is exhausted or it already forwarded that message to that device.
6. Rescue Node enables `I AM A RESCUE NODE`.
7. When internet returns, Rescue Node uploads unsynced emergencies to Firebase.

## Firebase Firestore Setup

1. Create a Firebase project.
2. Create Firestore database.
3. Add an Android app with package name `org.lifesaver.dtn`.
4. Download `google-services.json`.
5. Place it at:

```text
android/app/google-services.json
```

6. Install FlutterFire CLI and run:

```bash
flutterfire configure
```

7. Firestore collection used:
   - `emergencies`

The app still opens without Firebase config; Rescue Node cloud sync reports unavailable until configuration is added.

## Google Maps Setup

Enable Maps SDK for Android in Google Cloud, then set your API key in:

```text
android/app/build.gradle
```

Replace:

```gradle
manifestPlaceholders += [GOOGLE_MAPS_API_KEY: ""]
```

with your key, and rebuild with:

```bash
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

## Gemini Setup

Build with:

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY
```

Without a key, the app uses an offline heuristic classifier.

## SQLite Schema

```sql
CREATE TABLE emergency_messages (
  messageId TEXT PRIMARY KEY,
  senderDevice TEXT NOT NULL,
  type TEXT NOT NULL,
  victims INTEGER NOT NULL,
  description TEXT NOT NULL,
  medicalEmergency INTEGER NOT NULL,
  priority TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  timestamp TEXT NOT NULL,
  status TEXT NOT NULL,
  photoPath TEXT,
  ttl INTEGER NOT NULL DEFAULT 3,
  relayCount INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE connected_devices (
  endpointId TEXT PRIMARY KEY,
  deviceName TEXT NOT NULL,
  connectedAt TEXT NOT NULL,
  lastSeenAt TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE sync_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  messageId TEXT,
  action TEXT NOT NULL,
  detail TEXT NOT NULL,
  createdAt TEXT NOT NULL
);

CREATE TABLE forwarding_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  messageId TEXT NOT NULL,
  deviceId TEXT NOT NULL,
  action TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  UNIQUE(messageId, deviceId)
);
```

## Build Note For This PC

Because the project lives inside OneDrive, Gradle native outputs can become OneDrive reparse-point files. Build with Gradle outputs redirected:

```powershell
$env:LIFESAVER_DTN_BUILD_DIR='C:\Users\sajid\AppData\Local\Temp\lifesaver_dtn_gradle_build'
flutter build apk --release
```

The APK may be generated in:

```text
C:\Users\sajid\AppData\Local\Temp\lifesaver_dtn_gradle_build\app\outputs\flutter-apk\app-release.apk
```
