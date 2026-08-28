# Alias Messaging App

Alias is a robust, cross-platform messaging application built with Flutter, Firebase, and Agora.

## Features

- User Authentication (Email/Password, Google)
- Real-time 1-to-1 Messaging
- Voice & Video Calls (Powered by Agora)
- Media Sharing (Images, Videos, Audio, Files) up to 30MB
- Push Notifications (FCM)
- Local Chat Backup & Restore (SQLite + Google Drive)

## Tech Stack

- **Framework**: Flutter 3.x+
- **State Management**: Riverpod (v2, code generation)
- **Routing**: Go Router
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions, Cloud Messaging)
- **Calls**: Agora RTC Engine (^6.3.2)
- **Local Database**: sqflite

## Prerequisites

- Flutter SDK (3.x or higher)
- Firebase CLI and FlutterFire CLI
- Node.js (v20+) for Cloud Functions

## Setup Guide

Follow these steps to set up the project locally:

1. **Clone the repository and open the project**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Set up Firebase**:
   - Create a new project in the [Firebase Console](https://console.firebase.google.com/).
   - Enable Authentication (Email/Password, Google).
   - Enable Firestore Database.
   - Enable Storage.
4. **Configure FlutterFire**:
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart`.
5. **Add Google Services Configs**:
   - Download `google-services.json` from Firebase and place it in `android/app/`.
   - Download `GoogleService-Info.plist` from Firebase and place it in `ios/Runner/`.
6. **Set up environment variables**:
   Edit `lib/core/config/app_config.dart` with your **Agora App ID** and **Giphy API Key**.
7. **Deploy Security Rules**:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only storage:rules
   ```
8. **Deploy Cloud Functions**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```
9. **Set Function Environment Variables**:
   Set your Agora App ID and Certificate in Firebase Cloud Functions config:
   ```bash
   firebase functions:config:set agora.app_id="YOUR_APP_ID" agora.certificate="YOUR_CERTIFICATE"
   ```
10. **Run Code Generation** for Riverpod and other generated files:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
11. **Run the App**:
    ```bash
    flutter run
    ```

## Architecture

The project follows a feature-based structure with distinct layers for UI, State (Providers), Services, and Models. Key directories include:
- `lib/core/` - Core configurations, theme, and constants.
- `lib/models/` - Data models.
- `lib/services/` - Firebase, Agora, and local DB services.
- `lib/providers/` - Riverpod providers for state management.
- `lib/widgets/` - Reusable UI components.
- `lib/screens/` - Main application screens.

## Firebase Security Rules

- **Firestore**: Restricts document access to authenticated users, ensuring that only participants of a chat can read/write messages, and only relevant users can manage calls.
- **Storage**: Limits file uploads to 30MB, restricts uploads to specific MIME types (audio, image, video, pdf), and ensures files in chat directories are uploaded only by participants.

## Limitations & Future Improvements

- Group chats are not currently supported.
- Need to implement end-to-end encryption (E2EE) for messages.
- Better error handling and retry mechanisms for media uploads.
