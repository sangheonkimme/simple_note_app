# Novita

A simple, modern note-taking application built with Flutter.

## ✨ Features

- **📝 Rich Note Editor**: Create notes with text or interactive checklists.
- **📂 Organize Your Way**: Group notes into folders and add tags for easy categorization.
- **🖼️ Image Attachments**: Add images to your notes from the gallery or camera.
- **🔍 Powerful Search**: Quickly find notes by searching titles, content, or tags.
- **🎨 Modern UI**: Includes a dark mode for comfortable viewing in low-light conditions.
- **📊 Analytics & Monitoring**: Integrated with Firebase Analytics and Crashlytics.

## 🚀 Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Local Database**: Isar
- **Backend Services**: Firebase

## ⚙️ Getting Started

This guide will help you get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Firebase account and the [Firebase CLI](https://firebase.google.com/docs/cli) configured.
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Setup

1.  **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd novita
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Configure Firebase:**

    Run `flutterfire configure` to connect the project to your own Firebase project. This will generate the necessary configuration files (like `firebase_options.dart`) that are excluded from version control.
    ```sh
    flutterfire configure
    ```

4.  **Run Code Generation:**

    This project uses code generation for database models and state management. Run the following command to generate the necessary files:
    ```sh
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

5.  **Run the app:**
    ```sh
    flutter run
    ```
