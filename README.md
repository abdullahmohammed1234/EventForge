# EventForge - Full-Stack Event Planning Platform

A production-ready full-stack event planning platform built with Flutter, Node.js, Express, MongoDB Atlas, and Cloudinary.

## 📋 Project Overview

EventForge is a mobile application for discovering, creating, and managing local events. Users can:

- **Authentication**: Register and login with email/password
- **Discover Events**: Browse events by category and city
- **Search**: Search events by title, description, or location
- **Maps Integration**: View events on map, get directions to events using OpenRouteService
- **Create Events**: Create events with cover images, categories, locations, and dates
- **Manage Events**: View, save, and register for events
- **User Profiles**: Manage profile with avatar and personal information
- **Safety Center**: Access emergency contacts and safety information for events

## 🏗 Architecture

### Backend (Node.js + Express)

- **Stack**: Node.js, Express, MongoDB Atlas, Mongoose, JWT, OpenRouteService
- **Structure**: MVC pattern with controllers, routes, models, middleware
- **Security**: bcrypt password hashing, JWT auth, helmet, cors, express-validator, morgan
- **Storage**: Local file uploads + Cloudinary for cloud image storage
- **Maps**: OpenRouteService for geocoding and directions

### Frontend (Flutter)

- **State Management**: Provider
- **Storage**: flutter_secure_storage for JWT tokens
- **HTTP Client**: http package
- **Maps**: Integration with OpenRouteService API

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- Flutter SDK 3.0+
- MongoDB Atlas account
- Cloudinary account (optional, for cloud image storage)

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

# Cloudinary Configuration (optional - for cloud image storage)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# OpenRouteService Configuration (for maps and directions)
OPENROUTESERVICE_API_KEY=your_openrouteservice_api_key
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

| Method | Endpoint | Description | Auth |
| ------ | ----------------------- | -------------------------------- | ---- |
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login user | No |
| GET | `/api/auth/me` | Get current user | Yes |
| POST | `/api/auth/logout` | Logout user | Yes |
| PUT | `/api/auth/profile` | Update user profile | Yes |
| POST | `/api/auth/upload-avatar` | Upload user avatar | Yes |
| GET | `/api/events` | Get all events (with filters) | No |
| GET | `/api/events/my-events` | Get user's created events | Yes |
| GET | `/api/events/registered` | Get events user registered for | Yes |
| GET | `/api/events/saved` | Get user's saved events | Yes |
| GET | `/api/events/:id` | Get event by ID | No |
| POST | `/api/events` | Create event | Yes |
| PUT | `/api/events/:id` | Update event | Yes |
| DELETE | `/api/events/:id` | Delete event | Yes |
| POST | `/api/events/upload-cover` | Upload event cover image | Yes |
| POST | `/api/events/:id/register` | Register for event | Yes |
| POST | `/api/events/:id/unregister` | Unregister from event | Yes |
| POST | `/api/events/:id/save` | Save event | Yes |
| POST | `/api/events/:id/unsave` | Unsave event | Yes |
| POST | `/api/maps/geocode` | Geocode an address | No |
| GET | `/api/maps/directions/:eventId` | Get directions to an event | No |

### Query Parameters for GET /api/events

| Parameter | Type | Description |
| --------- | ---- | -------------------------------------------------------------------------------------------- |
| page | integer | Page number (default: 1) |
| limit | integer | Items per page (default: 20) |
| city | string | Filter by city |
| category | string | Filter by category (music, sports, arts, food, technology, business, social, outdoor, other) |
| search | string | Search events by title/description |

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
static const String apiBaseUrl = 'http://192.168.x.x:3000/api'; // Your local IP
// For Android Emulator use: http://10.0.2.2:3000/api
// For iOS Simulator use: http://localhost:3000/api
// For Physical device use: http://YOUR_IP:3000/api
```

Also update `event_planner/.env`:
```
LOCAL_IP=192.168.x.x  # Your computer's local IP address
```

### 3. Run Flutter App

```bash
cd event_planner
flutter run
```

---

## 🗺️ OpenRouteService Setup (Optional)

For maps and directions functionality:

1. Create a free OpenRouteService account at https://openrouteservice.org
2. Get your API key from the dashboard
3. Add credentials to `backend/.env`

```env
OPENROUTESERVICE_API_KEY=your_api_key
```

If OpenRouteService is not configured, geocoding and directions features will not work.

---

## ☁️ Cloudinary Setup (Optional)

For cloud image storage that works across all devices:

1. Create a free Cloudinary account at https://cloudinary.com
2. Get your credentials from the Cloudinary Dashboard:
   - Cloud Name
   - API Key
   - API Secret
3. Add credentials to `backend/.env`

If Cloudinary is not configured, images will be stored locally (only works on the computer running the backend).

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

---

## 📁 Project Structure

### Backend

```
backend/
├── src/
│   ├── config/         # Database & Cloudinary configuration
│   ├── controllers/    # Business logic
│   ├── middleware/     # Auth, error handling
│   ├── models/         # Mongoose schemas
│   ├── routes/         # API routes
│   ├── utils/          # Helper utilities (upload, etc.)
│   └── app.js          # Express app
├── server.js           # Entry point
├── package.json
└── .env.example
```

### Flutter

```
event_planner/
├── lib/
│   ├── core/
│   │   ├── api/           # API services (auth, events, maps)
│   │   ├── config/        # App configuration
│   │   └── utils/         # Helper utilities
│   ├── features/
│   │   ├── auth/          # Login, register, auth provider
│   │   ├── events/        # Events feed, create, detail, provider
│   │   ├── discover/      # Discover screen with categories
│   │   ├── profile/       # Profile screen
│   │   ├── search/        # Search functionality
│   │   ├── maps/          # Map view and directions
│   │   ├── safety/        # Safety center
│   │   └── notifications/ # Notifications
│   └── main.dart
├── pubspec.yaml
└── android/
```

---

## 🔐 Security Notes

- Never commit `.env` files to version control
- Change JWT_SECRET in production
- Use HTTPS in production
- Configure Cloudinary for production image storage

---

## 🛠 Future Features

- Groups functionality
- Real-time chat
- Push notifications
- External API integration
- Ranking system
- Admin dashboard
- Event check-ins
- Location-based notifications

---

## 📄 License

MIT License
