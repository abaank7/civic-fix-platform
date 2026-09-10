# 🏙️ CivicFix Platform

CivicFix is a full-stack, AI-powered civic issue reporting platform. It empowers citizens to report local infrastructure issues (like potholes, broken streetlights, or water leaks) via a mobile app, while providing city administrators with a real-time web dashboard to track, categorize, and resolve them.

## 🚀 Live Links
* **Web Dashboard (Vercel):** https://civic-fix-platform.vercel.app/
* **Admin Dashboard (Vercel):** https://civic-fix-platform.vercel.app/admin/
* **Backend API (Render):** https://civic-fix-platform.onrender.com/
* **Mobile App (Android):** https://github.com/abaank7/civic-fix-platform/releases/download/v1.0.0/CivicFix.apk

## 🧠 System Architecture
This platform is built using a modern, decoupled microservices architecture:

1. **Mobile App (Flutter):** Cross-platform mobile client for citizens to capture images, fetch GPS coordinates, and submit reports.
2. **Backend API (FastAPI):** High-performance Python backend that orchestrates data flow, handles business logic, and communicates with AI models.
3. **AI Engine (OpenAI Vision):** Automatically analyzes uploaded images and descriptions to categorize the issue (e.g., PWD, KPDCL, SMC) and flag invalid reports.
4. **Cloud Storage (Cloudinary):** Ephemeral-free, secure CDN for hosting user-uploaded images.
5. **Database (Supabase / PostgreSQL):** Cloud database utilizing a Session Pooler for robust, persistent connection handling.
6. **Web Dashboard (React):** Real-time administration panel for city officials to view map data and update ticket statuses.

## 📁 Repository Structure
* `/frontend_mobile`: Flutter Android/iOS application.
* `/backend`: Python FastAPI server.
* `/frontend_web`: React.js administration dashboard.

## 🛠️ Key Features
* **AI Auto-Categorization:** Uses GPT-5-mini vision capabilities to route issues to the correct department automatically.
* **Geospatial Mapping:** Integrates OpenStreetMap/FlutterMap for precise location tracking.
* **Secure Cloud Media:** Direct-to-cloud image streaming via Cloudinary.
* **Production Ready:** Fully deployed across Render, Vercel, and Supabase.