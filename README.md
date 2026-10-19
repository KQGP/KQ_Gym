# KQ_Gym — Gym Membership Manager

A **Flutter app** for managing gym members: add/edit members, track expirations, view dashboard stats, and filter by expiry (expired / expiring tomorrow). Uses local SQLite storage.

## ✨ Features

- ➕ Add / ✏️ edit members
- 📋 Member list with filters
- ⏰ Expired members page
- ⚠️ Expiring-tomorrow page
- 📊 Dashboard stats
- 💾 Local SQLite database (sqflite)

## 🧱 Tech Stack

- **Flutter** (Dart SDK ^3.7)
- **State management:** Riverpod
- **Storage:** sqflite, path_provider

## 📁 Project Structure

```
lib/
├── main.dart
├── member.dart / member_provider.dart
├── db_helper.dart
├── add_member_form.dart / edit_member_form.dart
├── expired_members_page.dart
├── expiring_tomorrow_page.dart
├── dashboard_stats.dart
└── filter_provider.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Dart ^3.7)

### Install & Run
```bash
flutter pub get
flutter run
```

### Build
```bash
flutter build apk
flutter build ios
```

## 📄 License
No license specified.