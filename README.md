# Fitness Tracker 🏃‍♂️📊

A comprehensive, responsive Flutter application designed to help users track their daily fitness activities, monitor nutritional intake, and achieve personal health goals. 

This project moves beyond manual logging, offering a centralized, data-driven system with real-time progress tracking, macro-nutrient breakdowns, and seamless cloud synchronization.

---

## ✨ Key Features

* **🔐 Secure Authentication**: User login & sign-up using Firebase, complete with background email verification and secure password management.
* **📊 Dynamic Dashboard**: Real-time overview of daily steps, calories burned, and nutrition intake with responsive circular and linear progress indicators.
* **🚶‍♂️ Step Tracking**: Live pedometer integration with historical logs to review past daily step counts and goal completions.
* **🥗 Nutrition Logging**: Add daily meals with automated macro tracking (Protein, Carbs, Fat) and view weekly/monthly intake charts.
* **⚙️ Goal Management**: Set and edit specific targets (Target Weight, Intake Goal, Burn Goal, Step Goal) and update personal profile details.
* **🌗 UI/UX & Theming**: Fully responsive design adapting to any screen size, complete with a seamless Light and Dark mode toggle.

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Dart)
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Backend**: [Firebase](https://firebase.google.com/) (Authentication & Cloud Firestore)
* **Hardware Integration**: `pedometer` & `permission_handler`
* **Local Storage**: `shared_preferences`

---

## 🚀 Getting Started

This project is a starting point for a Flutter application. To get a copy running on your local machine for development and testing, follow these steps:

### Prerequisites
* Flutter SDK (^3.11.0)
* Android Studio or VS Code
* A Firebase Project (for backend services)
