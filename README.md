# NutriScan: AI-Powered Nutrition Analysis

[![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud_Functions-FFCA28?logo=firebase)](https://firebase.google.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Gemini](https://img.shields.io/badge/Google-Gemini_2.5-4285F4?logo=google)](https://deepmind.google/technologies/gemini/)

---

## Screenshots
<div align="center">
  <img src="screenshots/home.png" width="250" />
  <img src="screenshots/analysis.png" width="250" />
  <img src="screenshots/diary.png" width="250" />
</div>

---

## Overview

**NutriScan** is a mobile application built with **Flutter**, leveraging **Google Gemini** through **Firebase Cloud Functions** to analyze food images and estimate nutritional information.

The AI estimates:
- Macronutrients (protein, carbohydrates, fat)
- Estimated portion weight
- Total calorie count
- Primary ingredients

---

## Features

- **AI-driven Image Analysis** – Nutrition estimation powered by Google Gemini 2.5 Flash  
- **Detailed Nutritional Data** – Calories, protein, carbs, fats, weight, and ingredients  
- **Daily Food Logging** – Track meals (Breakfast, Lunch, Dinner, Snacks)  
- **Daily Summary** – View total calorie and macronutrient intake  
- **Modern Dark UI** – Clean and minimalist design optimized for readability  
- **Secure Backend** – API keys protected via Firebase Cloud Functions  
- **Goal Management** – Set daily calorie and macro targets  
- **Historical Trends** – Track progress over time *(Coming Soon)*  

---

## Architecture

```

┌─────────────────┐
│   Flutter App   │
│     (Dart)      │
└────────┬────────┘
       HTTPS
         ▼
┌─────────────────┐
│    Firebase     │
│ Cloud Functions │
│    (Node.js)    │
└────────┬────────┘
   Secret API Key
         ▼
┌─────────────────┐
│  Google Gemini  │
│   2.5 Flash API │
└─────────────────┘

````

---

## Prerequisites

Before setup, ensure the following are installed and configured:

- **Flutter SDK** 3.19.0+ ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK** 3.3.0+ (included with Flutter)
- **Android Studio** or **VS Code** with Flutter/Dart extensions  
- **Firebase CLI** ([Install Guide](https://firebase.google.com/docs/cli))
- **Node.js** 18+ and npm ([Download](https://nodejs.org/))
- **CocoaPods** (for iOS builds) ([Install](https://cocoapods.org/))
- **Firebase Project** – Blaze Plan required for Cloud Functions with secrets  
- **Gemini API Key** – Obtain via [Google AI Studio](https://makersuite.google.com/app/apikey)

---

## Setup Guide

### 1. Clone the Repository
```bash
git clone <your-repository-url>
cd <your-project-directory>
````

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase Project

* **Create or Select Project** in [Firebase Console](https://console.firebase.google.com)
* Enable the following services:

  * Cloud Functions
  * Secret Manager
  * Billing (Blaze plan)

---

### 4. Configure Firebase for the Flutter Application

#### Android Setup

1. Register your Android app with package name `com.example.calorie_counter_app`.
2. Download `google-services.json`.
3. Place it in `android/app/`. *(excluded from Git via `.gitignore`)*
4. (Optional) Configure `android/key.properties` for release signing.

#### iOS Setup

1. Register your iOS app with your Bundle ID.
2. Download `GoogleService-Info.plist`.
3. Add it to `ios/Runner/` via Xcode. *(excluded from Git)*
4. Install CocoaPods dependencies:

   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

---

### 5. Configure Firebase Functions

```bash
cd functions
npm install
```

#### Set Up Gemini API Key Secret

```bash
# Ensure Firebase CLI is logged in and correct project is selected
firebase login
firebase use calorie-counter-app-bf67e

# Set secret
firebase functions:secrets:set GEMINI_API_KEY
```

Enter your Gemini API key when prompted.
The key will be securely stored in Google Secret Manager.

---

### 6. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

---

### 7. Run the Flutter Application

```bash
flutter run
```

---

## Backend Details (Firebase Functions)

**Function:** `analyzeImage`

* **Location:** `functions/index.js`
* **Model:** Google Gemini 2.5 Flash
* **Trigger:** HTTPS Callable Function
* **Authentication:** via `process.env.GEMINI_API_KEY` (stored in Secret Manager)

---

## Environment Variables & Secrets

| File / Secret                         | Purpose                    | Included in Git? |
| ------------------------------------- | -------------------------- | ---------------- |
| `functions/.env`                      | Local testing (Gemini key) | No               |
| `android/app/google-services.json`    | Android Firebase config    | No               |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config        | No               |
| `android/key.properties`              | Android signing keys       | No               |

---

## Troubleshooting

### “Failed to analyze image”

```bash
firebase deploy --only functions
firebase functions:log --only analyzeImage
firebase functions:secrets:access GEMINI_API_KEY
```

* Verify function deployment and Gemini key access
* Check Google Cloud Billing status

### Build Errors (Android)

```bash
flutter clean && flutter pub get
```

* Ensure `google-services.json` is placed correctly
* Check Gradle version compatibility

### Build Errors (iOS)

```bash
cd ios && pod install --repo-update && cd ..
```

* Verify `GoogleService-Info.plist` placement in Xcode
* Clean Xcode build folder

---

## Contributing

Contributions are welcome! Please follow the standard fork and pull request workflow.

---

## License

This project is distributed under the **GNU General Public License v3.0**.
See the [LICENSE](LICENSE) file for full details.

---

## Credits

* **Developer:** HruHruStudio
* **AI Model:** Google Gemini 2.5 Flash
* **Framework:** Flutter by Google
* **Backend:** Firebase Cloud Functions
* **Design:** Material Icons & Custom Assets

---

## Contact

**Website:** hruhrustudio.site
**GitHub:** [@krutoychel24](https://github.com/krutoychel24)

```
```
