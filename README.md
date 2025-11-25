# Calcx - Hidden Chat Calculator

Calcx is a Flutter app that appears to be a normal calculator but contains a hidden chat system powered by Firebase Authentication and Firestore.

## Features

### 🧮 Calculator Screen
- Fully functional calculator with basic operations (`+`, `-`, `×`, `÷`)
- Modern, iOS-style calculator UI
- Button press animations
- **Secret Code**: Enter `2082-05-16` and press `=` to unlock the hidden login screen

### 🔐 Authentication
- Firebase Authentication with email/password
- Login and signup screens
- Auto-login from saved session
- Secure user management

### 💬 Chat System
- Real-time messaging using Firestore
- User contact management
- Chat list with last message preview
- Message bubbles (right = current user, left = other user)
- Timestamp display

### 🔒 Security Features
- Calculator is the default UI (hidden chat system)
- Auto-lock when app goes to background
- Emergency exit button to instantly return to calculator
- No notifications (no FCM)

## Project Structure


```
lib/
├── main.dart
├── screens/
│   ├── calculator_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── chat_list_screen.dart
│   ├── chat_screen.dart
│   └── add_contact_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── secret_code_service.dart
└── widgets/
├── message_bubble.dart
└── contact_tile.dart

 ```


## Usage

1. **Unlock Hidden Features**
   - Open the calculator
   - Enter the secret code: `2082-05-16`
   - Press `=` to unlock the login screen

2. **Create Account**
   - Sign up with email and password
   - Optionally add a display name

3. **Add Contacts**
   - Use the "Add Contact" button to find and add other users

4. **Start Chatting**
   - Select a contact from the chat list
   - Send messages in real-time

5. **Security**
   - App auto-locks when backgrounded
   - Use the home icon for emergency exit
   - Logout to return to calculator

## Technologies Used
- **Flutter** - UI Framework
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **SharedPreferences** - Local session storage
- **Intl** - Date/time formatting

## Requirements
- Flutter SDK 3.9.2 or higher
- Firebase project with Authentication and Firestore enabled
- Android Studio / Xcode (for mobile development)

## Notes
- The secret code is hardcoded as `2082-05-16` in `lib/services/secret_code_service.dart`
- Auto-login stores email locally (password storage is not recommended for production)
- Firestore security rules should be configured for production use
- No push notifications are implemented

## License
This project is for educational/demonstration purposes.

