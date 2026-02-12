# 💰 Money Mitra

Money Mitra is a **personal finance education and assistance app** built with **Flutter + Firebase**, designed to help users understand money, manage finances responsibly, and make better financial decisions. The app focuses on **learning-first finance**, combining structured lessons, progress tracking, and secure Firebase-backed infrastructure.

---

## 🧠 What Problem Does Money Mitra Solve?

Many users struggle with:

* Poor financial literacy
* Bad money habits
* Lack of structured, beginner-friendly finance education
* Unsafe or confusing finance apps

Money Mitra solves this by offering **guided finance learning**, **decision-based questions**, and a **secure, scalable architecture**.

---

## 🚀 Tech Stack

### Frontend

* **Flutter** (Dart)
* Supports **Android, iOS, Web, Windows, macOS, Linux**

### Backend / Services

* **Firebase Authentication**
* **Cloud Firestore**
* **Firebase Storage** (if needed)
* **Firebase Cloud Functions (Node.js)** for admin/secure operations

---

## 📁 Project Structure (Important)

```text
money_mitra/
│
├── lib/                     # Main Flutter source code
│   ├── screens/             # UI screens
│   ├── services/            # Firestore / Auth services
│   ├── models/              # Data models
│   └── widgets/             # Reusable UI components
│
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── web/                     # Web support
├── windows/ macos/ linux/   # Desktop support
│
├── functions/               # (Optional) Firebase Cloud Functions
│   ├── index.js
│   └── package.json
│
├── pubspec.yaml              # Flutter dependencies
├── pubspec.lock              # Locked dependency versions
├── firebase.json             # Firebase configuration
├── .firebaserc               # Firebase project mapping
├── .gitignore                # Git ignore rules
└── README.md                 # Project documentation
```

---

## 🔐 Security Rules (VERY IMPORTANT)

### ❌ What NOT to do

* ❌ Do NOT commit `serviceAccountKey.json`
* ❌ Do NOT store admin keys inside `lib/`
* ❌ Do NOT push `node_modules/` or `build/`

### ✅ Correct Practice

* Flutter app uses **Firebase client SDK only**
* Admin / privileged logic goes into **Cloud Functions**
* Secrets stay local or in environment variables

---

## 📦 Setup Instructions

### 1️⃣ Clone the repository

```bash
git clone https://github.com/lakshya0511/Money-Mitra.git
cd Money-Mitra
```

---

### 2️⃣ Flutter setup

Make sure Flutter is installed:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

---

### 3️⃣ Firebase setup (Frontend)

1. Create a Firebase project
2. Add Android / iOS / Web apps
3. Download config files:

   * `google-services.json` → `android/app/`
   * `GoogleService-Info.plist` → `ios/Runner/`
4. Enable:

   * Firebase Authentication
   * Cloud Firestore

---

### 4️⃣ Node.js setup (ONLY if using Cloud Functions)

> ⚠️ This is required **only for backend/admin logic**

Install Node.js (LTS recommended):

```bash
node -v
npm -v
```

Inside `functions/` folder:

```bash
cd functions
npm install
```

Run locally:

```bash
firebase emulators:start
```

Deploy functions:

```bash
firebase deploy --only functions
```

---

## 🧩 App Features

### 📚 Finance Learning Modules

* Structured finance sections
* Lesson-based learning flow
* Search & filter lessons

### 🧠 Smart Question Types

* **Decision-based questions** (real-life scenarios)
* **Reflection questions** (user reasoning)
* **Confidence tracking** after lessons

### 🔁 Continue Learning

* Resume where the user left off
* Track completed lessons

### 👤 User Management

* Firebase Authentication
* Secure user profiles

### 🌗 Theme Support

* Light mode
* Dark mode
* Consistent app-wide theme

### 🔐 Security First

* No admin secrets in frontend
* Firestore rules enforced
* Backend logic isolated

---

## 🛡️ Git & Environment Rules

### Files ignored by Git

* `node_modules/`
* `build/`
* `.dart_tool/`
* `lib/**/serviceAccountKey.json`
* `.firebase/`

### If you add a secret by mistake

1. Remove it immediately
2. Revoke the key in Firebase Console
3. Never reuse compromised keys

---

## 📌 Future Roadmap

* AI-based financial guidance
* Personalized learning paths
* Expense tracking & insights
* Wallet & budgeting tools
* Multi-language support

---

## 🤝 Contribution Guidelines

1. Create a new branch

   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Commit changes
3. Open a Pull Request

---

## 📄 License

This project is currently under active development.

---

## 🙌 Author

**Lakshya**

Money Mitra – *Learn money. Manage money. Master money.*
