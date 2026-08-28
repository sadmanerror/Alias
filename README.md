# 💬 Alias — Private & Secure Real-Time Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS_%7C_Web-green.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter" />
  <img src="https://img.shields.io/badge/Release-v1.0.0-sage.svg" alt="Release" />
  <img src="https://img.shields.io/badge/Android%20APK-~30MB-brightgreen.svg" alt="APK Size" />
  <img src="https://img.shields.io/badge/License-MIT-orange.svg" alt="License" />
</p>

<p align="center">
  <a href="https://github.com/sadmanerror/Alias/releases/latest/download/Alias-arm64-v8a.apk">
    <img src="https://img.shields.io/badge/🤖_Download_Android_APK-v1.0.0-2ea44f?style=for-the-badge&logo=android&logoColor=white" height="42" alt="Download APK" />
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
| **`Alias.apk`** | **~30MB** | Universal Link | [📥 Download](https://github.com/sadmanerror/Alias/releases/latest/download/Alias.apk) |

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

## ✨ Key Features

- ⚡ **Instant Messaging**: Real-time 1-on-1 private chat with instant delivery indicators.
- 🖼️ **Free Device Media & Profile Pictures**: Pick photos directly from your Camera or Gallery without needing paid cloud storage.
- 🎙️ **Voice Messaging**: Audio recording with interactive waveform playback.
- 📹 **Audio & Video Calls**: Real-time audio and video calling powered by Agora RTC.
- 🎨 **Minimalist Design**: Soft Sage Green and Warm Sand visual theme.
- 🔒 **Private & Secure**: Firestore security rules and encrypted channels.

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x+
- **State Management**: Riverpod (v2)
- **Routing**: Go Router
- **Backend & Database**: Firebase (Auth, Firestore, Cloud Messaging)
- **RTC Engine**: Agora Audio & Video SDK
- **Local DB**: SQLite (`sqflite`)

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
