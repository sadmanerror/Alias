# 💬 Alias — Private & Secure Real-Time Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS_%7C_Web-green.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter" />
  <img src="https://img.shields.io/badge/Release-v1.3.0-sage.svg" alt="Release" />
  <img src="https://img.shields.io/badge/Android%20APK-~30MB-brightgreen.svg" alt="APK Size" />
  <img src="https://img.shields.io/badge/License-MIT-orange.svg" alt="License" />
</p>

<p align="center">
  <a href="https://github.com/sadmanerror/Alias/releases/latest/download/Alias-arm64-v8a.apk">
    <img src="https://img.shields.io/badge/🤖_Download_Android_APK-v1.3.0-2ea44f?style=for-the-badge&logo=android&logoColor=white" height="42" alt="Download APK" />
  </a>
  <a href="https://sadmanerror.github.io/Alias/">
    <img src="https://img.shields.io/badge/🍎_Open_on_iOS_&_Web-Live_App-000000?style=for-the-badge&logo=apple&logoColor=white" height="42" alt="iOS Web App" />
  </a>
  <a href="MASTER_GUIDE.md">
    <img src="https://img.shields.io/badge/📘_Read_Master_Architecture_Guide-1f2328?style=for-the-badge&logo=gitbook&logoColor=white" height="42" alt="Master Guide" />
  </a>
</p>

---

> 📖 **New to this project or Flutter development?** Read the complete **[Master Architecture & Engineering Guide (MASTER_GUIDE.md)](MASTER_GUIDE.md)** to learn how every single feature, tool, backend pipeline, and bug fix was built from the ground up!

---

## 📲 Downloads & Installation

### 🤖 For Android Users (Direct APK ~30MB)

| Package | Size | Target Devices | Direct Download |
|---|---|---|---|
| **`Alias-arm64-v8a.apk`** | **~30MB** | Modern Android Phones (Recommended) | [📥 Download](https://github.com/sadmanerror/Alias/releases/latest/download/Alias-arm64-v8a.apk) |
| **`Alias-armeabi-v7a.apk`** | **~25MB** | Older 32-bit Android Phones | [📥 Download](https://github.com/sadmanerror/Alias/releases/latest/download/Alias-armeabi-v7a.apk) |
| **`Alias.apk`** | **~30MB** | Universal Link (Arm64 Optimized) | [📥 Download](https://github.com/sadmanerror/Alias/releases/latest/download/Alias.apk) |

> 💡 **App Size Guarantee**: Thanks to architecture-split compilation (`--split-per-abi`), the downloaded APK is only **~25MB to 30MB** (far below standard 100MB+ fat packages).

#### How to install on Android:
1. Tap the **Download** link above directly from your Android phone.
2. Open the downloaded `.apk` file.
3. If prompted, enable *"Install from unknown sources"*.
4. Launch **Alias** and start chatting!

---

### 🍎 For iPhone / iOS Users (Install via Safari)

Because Apple restricts direct `.apk` installations, iOS users can install **Alias** directly to their iPhone home screen with **zero setup and zero fees**:

1. Open **[https://sadmanerror.github.io/Alias/](https://sadmanerror.github.io/Alias/)** in **Safari** on your iPhone.
2. Tap the **Share icon (`↑`)** at the bottom of the screen.
3. Scroll down and tap **"Add to Home Screen"** (`➕`).
4. Tap **Add** in the top-right corner.
5. **Alias** is now installed on your iPhone home screen just like a regular App Store app!

---

## ✨ What's New in v1.3.0

### 🚀 Key Improvements & Fixes:
- 🎵 **OG Nokia 3310 Classic Monophonic Ringtone**:
  - Replaced the heavy 7.37MB ringtone with an authentic Nokia 3310 tune (`~396KB`), shaving substantial size off the app.
  - Plays continuously on incoming calls and releases hardware audio resources immediately upon answering or declining.
- 📞 **Agora Voice Transmission Resolved**:
  - Configured Agora audio engine scenario to `AudioScenarioType.audioScenarioMeeting` with `AudioProfileType.audioProfileSpeechStandard`.
  - Enables Android `MODE_IN_COMMUNICATION` with hardware acoustic echo cancellation and unmuted microphone pipeline.
- 📲 **WhatsApp-Style Full-Screen Incoming Calls**:
  - When the app is active, incoming calls immediately trigger the full-screen `IncomingCallScreen` with ringtone and caller info.
  - Clicking incoming call notifications launches straight into the call screen.
- 🔔 **Background & Killed App Notifications (Cloud Function Fix)**:
  - Updated Cloud Functions Firestore trigger from `.onUpdate()` to `.onWrite()`, ensuring newly initiated calls (`onCreate`) immediately dispatch high-priority FCM call alerts to the callee.
  - Updated Flutter `firebaseMessagingBackgroundHandler` to display incoming calls and chat notifications via `NotificationService` when the app is terminated or in background.
- 🛡️ **Phone Call Permissions Sheet & Pre-flight Checks**:
  - On launch, users are prompted with a stylish permission primer sheet explaining microphone and camera requirements for calls.
  - Pre-flight checks prevent dead call states if microphone permission is denied.
- 🖼️ **Left-Side Chat Head Avatar Fix**:
  - Replaced broken image loading with a stateful fallback in `UserAvatar` and `ChatBubble` with Base64 memory decoding, fixing the blank sage-green circle bug.

---

## ✨ What's New in v1.2.0

### 🚀 New Features:
- 👥 **Group Voice Calls**:
  - Live low-latency Agora multi-participant audio conference rooms.
  - Interactive participant grid displaying live connections, mute statuses, and speak indicators.
  - In-app group call notification and sticky persistent top banner allowing users to join, return, or leave smoothly.
- 🖼️ **Messenger-Style Media Preview Before Sending**:
  - Full-screen media preview sheet when selecting photos or videos.
  - Add captions, zoom/pinch to inspect, play/pause video before confirming.
  - Cancel option prevents accidental sends on misclicks.
- 🗑️ **Photo & Message Unsend**:
  - Sender 3-dot overlay button on sent photos and videos (plus long-press context menu).
  - Permanent "Unsend" removes the media for everyone in the conversation.
- 🎵 **iPhone Ringtone for Incoming Calls**:
  - Authentic looped ringtone plays on incoming calls (callee side only) and stops immediately when accepted, declined, or dismissed.

### 🐛 Bug Fixes & Refinements:
- 🎙️ **Voice Messages Fixed**: Accurate recording duration tracking via stopwatch, permission verification, and robust multi-source playback (supporting Base64 data URIs, HTTP URLs, and device storage).
- 🔊 **In-Call Voice Transmission Fixed**: Agora RTC audio profiling (`audioProfileDefault`, `audioScenarioDefault`), recording/playback volume boost (100%), and channel deduplication preventing join collision errors.
- 🔔 **WhatsApp-Style Notifications**:
  - Root-level global message & call listener (`RootNotificationHandler`).
  - Notification panel displays the sender's actual username and message snippet.
  - Silent in-chat suppression (messages inside active chat don't generate popups).
- 🖼️ **Chat List Profile Photos**: Stream and future dual-source resolution in `ChatTile` guarantees profile photos display in chat heads.
- 📱 **Android System Back Button**: Full `PopScope` integration ensures pressing the hardware back button inside a chat navigates smoothly back to the home screen instead of exiting the app.
- 🎨 **Android Launcher Icon**: Replaced default Flutter icon with the new Alias branded logo across all Android mipmap resolutions.
- ℹ️ **Dynamic Version Display**: Settings "About" screen automatically reads live package info (`v1.2.0`).

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x+
- **State Management**: Riverpod (v2)
- **Routing**: Go Router
- **Backend & Database**: Firebase (Auth, Firestore, Cloud Messaging)
- **RTC Engine**: Agora Audio & Video SDK (`agora_rtc_engine`)
- **Local DB**: SQLite (`sqflite`)
- **Notifications**: Flutter Local Notifications & Firebase Messaging
- **GIFs**: Giphy REST API & Curated CDN Library

---

## 🚀 Local Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/sadmanerror/Alias.git
   cd Alias
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

4. **Build Lightweight Release APKs (< 35MB)**:
   ```bash
   flutter build apk --release --split-per-abi --no-tree-shake-icons
   ```
