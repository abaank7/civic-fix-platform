# 📱 CivicFix Mobile App

A cross-platform mobile application built with Flutter. This app empowers citizens to easily report civic infrastructure issues (like potholes, broken streetlights, or water leaks) by capturing photo evidence and precise GPS geolocation data.

## 🚀 Tech Stack
* **Framework:** Flutter / Dart
* **Maps:** `flutter_map` & OpenStreetMap
* **Networking:** `http` for REST API communication
* **Security:** Compile-time secret injection via `--dart-define`

## ✨ Key Features
* **Live Issue Feed:** View reported issues in real-time, complete with status tags and timestamps.
* **Smart Filtering:** Filter civic issues by category (e.g., PWD, KPDCL, SMC) or resolution status.
* **Interactive Mini-Map:** View exact incident locations via embedded OpenStreetMap integration.
* **Secure API Communication:** Communicates seamlessly with the live Python FastAPI backend.

## 🔐 Security Note: Compile-Time Secrets
To prevent sensitive Supabase API keys from being leaked in version control, this app utilizes Flutter's built-in `String.fromEnvironment()` method. Configuration variables are never hardcoded in the repository. Instead, they are injected securely via the terminal at compile time.

