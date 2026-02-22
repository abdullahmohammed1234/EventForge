# Event Forge Michelle Changed - Full-Stack Prototype

A production-ready full-stack prototype for an event planning platform built with Flutter, Node.js, Express, and MongoDB Atlas.

## 📋 Project Overview

This is Phase 1 of the Event Planner application, which includes:

- User registration & login with JWT authentication
- Event creation and viewing
- Clean, scalable architecture ready for future features

## 🏗 Architecture

### Backend (Node.js + Express)

- **Stack**: Node.js, Express, MongoDB Atlas, Mongoose, JWT
- **Structure**: MVC pattern with controllers, routes, models, middleware
- **Security**: bcrypt password hashing, JWT auth, helmet, cors, express-validator, morgan

### Frontend (Flutter)

- **State Management**: Provider
- **Storage**: flutter_secure_storage for JWT tokens
- **HTTP Client**: dio, http

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- Flutter SDK 3.0+
- MongoDB Atlas account

---

## 🔧 Backend Setup

### 1. Configure Environment Variables

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your values:

```env
PORT=3000
NODE_ENV=development
MONGODB_URI=your_mongodb_atlas_connection_string
JWT_SECRET=your_secure_jwt_secret
JWT_EXPIRES_IN=7d
FRONTEND_URL=http://localhost:3001
```

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Run Backend

```bash
# Development
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:3000`

### 4. API Endpoints

| Method | Endpoint                | Description                   | Auth |
| ------ | ----------------------- | ----------------------------- | ---- |
| POST   | `/api/auth/register`    | Register new user             | No   |
| POST   | `/api/auth/login`       | Login user                    | No   |
| GET    | `/api/auth/me`          | Get current user              | Yes  |
| POST   | `/api/auth/logout`      | Logout user                   | Yes  |
| GET    | `/api/events`           | Get all events (with filters) | No   |
| GET    | `/api/events/my-events` | Get user's created events     | Yes  |
| GET    | `/api/events/:id`       | Get event by ID               | No   |
| POST   | `/api/events`           | Create event                  | Yes  |
| PUT    | `/api/events/:id`       | Update event                  | Yes  |
| DELETE | `/api/events/:id`       | Delete event                  | Yes  |

### Query Parameters for GET /api/events

| Parameter | Type    | Description                                                                                  |
| --------- | ------- | -------------------------------------------------------------------------------------------- |
| page      | integer | Page number (default: 1)                                                                     |
| limit     | integer | Items per page (default: 20)                                                                 |
| city      | string  | Filter by city                                                                               |
| category  | string  | Filter by category (music, sports, arts, food, technology, business, social, outdoor, other) |

---

## 📱 Flutter Setup

### 1. Install Dependencies

```bash
cd event_planner
flutter pub get
```

### 2. Configure API URL

Edit `lib/core/config/app_config.dart` if your backend runs on a different URL:

```dart
static const String apiBaseUrl = 'http://192.168.4.28:3000/api'; // Default
// For Android Emulator use: http://10.0.2.2:3000/api
// For iOS Simulator use: http://localhost:3000/api
// For Physical device use: http://YOUR_IP:3000/api
```

### 3. Run Flutter App

```bash
cd event_planner
flutter run
```

---

## 🗄️ MongoDB Atlas Setup Guide

1. **Create Account**: Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)

2. **Create Cluster**:
   - Click "Build a Database"
   - Choose "Free Tier" (M0)
   - Create cluster name (e.g., "event-planner")

3. **Create Database User**:
   - Go to "Database Access"
   - Add new user with "Read and Write to any database" permissions

4. **Network Access**:
   - Go to "Network Access"
   - Add IP Address: `0.0.0.0/0` (allows all IPs for development)

5. **Get Connection String**:
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string
   - Replace `<password>` with your database user's password

## 📁 Project Structure

### Backend

```
backend/
├── src/
│   ├── config/         # Database configuration
│   ├── controllers/    # Business logic
│   ├── middleware/     # Auth, error handling
│   ├── models/         # Mongoose schemas
│   ├── routes/        # API routes
│   ├── utils/         # Helper utilities
│   └── app.js         # Express app
├── server.js          # Entry point
├── package.json
└── .env.example
```

### Flutter

```
event_planner/
├── lib/
│   ├── core/
│   │   ├── api/           # API services (auth, events)
│   │   ├── config/        # App configuration
│   │   └── utils/         # Helper utilities
│   ├── features/
│   │   ├── auth/          # Login, register, auth provider
│   │   ├── events/        # Events feed, create, provider
│   │   └── profile/       # Profile screen
│   └── main.dart
├── pubspec.yaml
└── android/
```

---

## 🔐 Security Notes

- Never commit `.env` files to version control
- Change JWT_SECRET in production
- Use HTTPS in production
- Implement rate limiting for API endpoints (Phase 2)

---

## 🛠 Future Features (Phase 2+)

- Groups functionality
- Real-time chat
- Push notifications
- External API integration
- Ranking system
- Admin dashboard

---

## 📄 License

MIT License
