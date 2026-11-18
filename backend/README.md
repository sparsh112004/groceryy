# Pantry Backend API

FastAPI backend service for the Household Pantry app ("Pantry").

## Stack
- **Framework:** FastAPI
- **ASGI Server:** Uvicorn
- **Database Driver:** Motor (async MongoDB driver for MongoDB Atlas)
- **Configuration:** python-dotenv

---

## Getting Started

### 1. Prerequisites
- Python 3.10+ (tested on Python 3.11)
- Access to a MongoDB Atlas cluster (or a local MongoDB instance)

### 2. Create and Activate a Virtual Environment
From the `backend/` directory:

**Windows (PowerShell):**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**macOS / Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Copy `.env.example` to create your local `.env`:

**Windows:**
```powershell
copy .env.example .env
```

**macOS / Linux:**
```bash
cp .env.example .env
```

Update `.env` with your actual MongoDB Atlas connection string:
```env
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/?retryWrites=true&w=majority
MONGODB_DB_NAME=pantry_db
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 5. Run the Server
From the `backend/` directory:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Verifying and Testing

### Health Check Endpoint
Once running, check the health endpoint:

```bash
curl http://localhost:8000/v1/health
```

Expected JSON response:
```json
{
  "status": "ok",
  "database": "connected",
  "environment": "development"
}
```
*(Note: If MongoDB is unreachable or unconfigured, `"database"` will be `"disconnected"` while `"status"` remains `"ok"`).*

### Interactive API Docs
Visit Swagger UI in your browser:
- Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
- ReDoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)
