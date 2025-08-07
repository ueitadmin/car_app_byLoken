# Loken CAR APP

This Flutter app tracks car kilometers in real-time using GPS and Google Maps.

## Features

- Start and stop trip tracking
- Shows route on Google Maps
- Calculates total distance traveled in kilometers
- Firebase and offline logging setup ready (you need to add `google-services.json`)

## Setup Instructions

1. Place your `google-services.json` file in `android/app/`.
2. Run `flutter pub get` to get dependencies.
3. Run `flutter run` to start the app.

## Firebase Setup

- Create a Firebase project with package name `com.example.lokencarapp`.
- Download `google-services.json` and place it as above.

## Next Steps

- Integrate Firestore and offline SQLite storage (can be added later).

---
