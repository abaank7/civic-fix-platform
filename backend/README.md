# ⚙️ CivicFix Backend API

A high-performance, asynchronous RESTful API built with **FastAPI** and **Python**. It serves as the core orchestration engine for the CivicFix platform—handling cloud image ingestion, automated multimodal AI classification, database transactions, and secure administrative controls.

---

## 🚀 Tech Stack

* **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Asynchronous Python web framework)
* **ASGI Server:** [Uvicorn](https://www.uvicorn.org/)
* **Database ORM:** [SQLAlchemy](https://www.sqlalchemy.org/) with PostgreSQL dialect
* **Database:** [Supabase](https://supabase.com/) (PostgreSQL with Supabase Session Connection Pooler)
* **AI Engine:** [OpenAI API](https://platform.openai.com/) (GPT-5-mini Multimodal Vision)
* **Media Storage:** [Cloudinary SDK](https://cloudinary.com/) (Direct stream-to-cloud CDN hosting)
* **Package Manager:** [`uv`](https://github.com/astral-sh/uv) (Ultra-fast Python package resolver)

---

## ✨ Core Architecture & Features

* **Multimodal AI Categorization:** Extracts incident context by feeding both the civic report text description and image URL into GPT-5-mini Vision to auto-route tickets to municipal departments (e.g., PWD, JSD, SMC, KPDCL).
* **Direct-to-Cloud Media Pipeline:** Implements memory-streamed image uploads straight to Cloudinary without persisting files to the server's local disk.
* **Resilient Database Layer:** Utilizes SQLAlchemy with Supabase's transaction pooler to maintain persistent connections across serverless and container restarts.
* **Role-Based Admin Protection:** Protected administrative endpoints guarded by secret key authentication for ticket status updates and report moderation.
* **Auto-Generated Documentation:** Interactive OpenAPI/Swagger documentation generated natively at `/docs`.

---

## 📡 API Endpoints Overview

### Public & Citizen Endpoints
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/issues/upload` | Streams raw image file to Cloudinary and returns CDN URL |
| `POST` | `/api/v1/issues/` | Analyzes image + text with Vision AI and stores new issue |
| `GET` | `/api/v1/issues/` | Fetches all public civic issues ordered by newest first |

### Admin Endpoints (Secured)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/admin/verify` | Validates admin master key |
| `PATCH` | `/api/v1/admin/issues/{id}` | Updates issue status (`Pending`, `In Progress`, `Resolved`) |
| `DELETE` | `/api/v1/admin/issues/{id}` | Deletes or flags invalid civic reports |

---

