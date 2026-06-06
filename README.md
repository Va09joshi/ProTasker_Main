<p align="center">
  <img src="https://raw.githubusercontent.com/Va09joshi/ProTasker_Main/main/assets/images/logo.png" alt="ProTasker Logo" width="140" />
</p>

<h1 align="center">ProTasker</h1>

<p align="center">
  <b>A modern, full-stack service marketplace app connecting Clients with trusted Service Providers.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Mgmt-0553B1" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## 📖 Overview

**ProTasker** is a production-ready Flutter application that creates a seamless two-sided marketplace between **Clients** who need household/professional services and **Service Providers** who offer them.

Clients can browse providers by category, post job requests describing their problems, receive proposals, chat in real time, book services, track progress, and leave reviews — all within a single, beautifully designed mobile app.

---

## ✨ Features

### For Clients
| Feature | Description |
|---|---|
| 🏠 **Smart Home Screen** | Personalized dashboard with categories, nearby providers, popular services, and active job posts |
| 📝 **Post a Problem** | Describe your issue with images, location, budget, and urgency — providers come to you |
| 🔍 **Browse Categories** | Tap any category (Cleaning, Plumbing, Electrical, etc.) to see real providers offering those services |
| 👤 **Provider Profiles** | View detailed profiles with bio, portfolio images, offered services, reviews, and ratings |
| 💬 **Real-time Chat** | Message any provider directly with text and image support, typing indicators, and read receipts |
| 📋 **Proposal System** | Receive and compare proposals from multiple providers for your posted jobs |
| ⭐ **Reviews & Ratings** | Leave detailed reviews after job completion to help the community |
| 📍 **Location Services** | Interactive Google Maps picker for precise job location |
| 🔔 **Notifications** | Stay updated on bookings, proposals, and messages |

### For Service Providers
| Feature | Description |
|---|---|
| 📊 **Dashboard** | Earnings overview, active jobs, and performance analytics with interactive charts |
| 📋 **Job Feed** | Browse and apply to open jobs posted by clients in your area |
| 💼 **Proposal Submission** | Submit competitive proposals with custom pricing and cover letters |
| 📅 **Job Management** | Track all bookings through their full lifecycle (pending → accepted → in-progress → completed) |
| 💬 **Client Chat** | Communicate directly with clients about job details |
| 👤 **Profile Management** | Showcase your skills, services, portfolio, and experience |

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.9+ / Dart 3.9+ |
| **State Management** | Riverpod (flutter_riverpod) |
| **Navigation** | GoRouter with custom slide + fade transitions |
| **Backend** | Firebase (Auth, Firestore, Cloud Messaging, Storage) |
| **Maps** | Google Maps Flutter + Geocoding + Geolocator |
| **Image Hosting** | Cloudinary |
| **UI/UX** | Google Fonts, Font Awesome, FL Chart, Shimmer loading, Cached Network Images |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── router/          # GoRouter configuration & route names
│   ├── services/        # Cloudinary, Location, Notification services
│   ├── theme/           # AppColors, AppTextStyles, AppDimensions
│   └── utils/           # Snackbar helpers, validators
├── features/
│   ├── auth/            # Login, Register, OTP, Profile Setup
│   ├── booking/         # Booking flow, detail, review, proof upload
│   ├── chat/            # Real-time messaging (1:1 per user pair)
│   ├── home/            # Client & Provider shells, dashboards, search
│   ├── jobs/            # Job posting, feed, proposals, detail
│   ├── location/        # Google Maps picker
│   ├── profile/         # Client/Provider profiles, public profiles
│   └── services/        # Service listing, filtering, detail
└── shared/
    ├── models/          # UserModel, BookingModel, ChatModel, etc.
    ├── providers/       # Auth state, user session providers
    └── widgets/         # Reusable UI components (Avatar, Cards, etc.)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.9.0`
- Dart SDK `>=3.9.0`
- A Firebase project with Auth, Firestore, and Messaging enabled
- Google Maps API key
- Cloudinary account

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Va09joshi/ProTasker_Main.git
cd ProTasker_Main

# 2. Install dependencies
flutter pub get

# 3. Create your environment file
cp .env.example .env
# Fill in your API keys in .env

# 4. Add Firebase config
# Place google-services.json in android/app/
# Place GoogleService-Info.plist in ios/Runner/

# 5. Run the app
flutter run
```

### Environment Variables

Create a `.env` file in the project root:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

---

## 🔒 Security

- All sensitive files (`.env`, `google-services.json`, keystores) are excluded via `.gitignore`
- Firestore security rules enforce role-based access control
- Firebase Authentication secures all API endpoints
- Environment variables are loaded at runtime via `flutter_dotenv`

---

## 📱 Screenshots

> Coming Soon — The app features a modern UI with smooth animations, glassmorphism elements, and a premium dark/light theme system.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ by <b>Vaibhav Joshi</b>
</p>
