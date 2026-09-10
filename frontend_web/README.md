# 💻 CivicFix Admin Dashboard

A responsive, React-based web administration portal designed for city officials and municipal departments. This dashboard acts as the centralized command center to view, track, and resolve civic issues reported by citizens via the mobile app.

---

## 🚀 Tech Stack

* **Framework:** React.js
* **Build Tool:** [Vite](https://vitejs.dev/) (Lightning-fast HMR and compilation)
* **Routing:** React Router DOM (Client-side routing)
* **API Integration:** Native `fetch` API for RESTful communication
* **Deployment:** [Vercel](https://vercel.com/)

---

## ✨ Key Features

* **Real-Time Data Feed:** Instantly view incoming civic reports with their associated photo evidence, timestamps, and AI-assigned categories (e.g., PWD, KPDCL, SMC).
* **Interactive Map View:** View exactly where an issue was reported using integrated geospatial data (latitude/longitude).
* **Secure Admin Portal:** A protected route requiring a master administrative key to access modification capabilities.
* **Issue Management:** Administrators can dynamically update ticket statuses (`Pending`, `In Progress`, `Resolved`) or delete/flag invalid reports.
* **Dynamic Status Colors:** Visual indicators help prioritize and quickly scan the resolution state of city infrastructure issues.

---

