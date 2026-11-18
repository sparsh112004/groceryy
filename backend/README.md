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

Update `.env` with your MongoDB Atlas connection string and secure `JWT_SECRET`:
```env
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/?retryWrites=true&w=majority
MONGODB_DB_NAME=pantry_db
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
JWT_SECRET=your-random-secret-key-at-least-32-chars
```
*(Note: The server will refuse to start if `JWT_SECRET` is not provided).*

### 5. Run the Server
From the `backend/` directory:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Verifying and Testing via Swagger UI (/docs)

Interactive API documentation is available at [http://localhost:8000/docs](http://localhost:8000/docs).

### Step-by-Step Flow:
1. **Health Check:**
   - Execute `GET /v1/health` to confirm server status and MongoDB connection.
2. **Signup (`POST /v1/auth/signup`):**
   - Provide a body:
     ```json
     {
       "name": "Jane Doe",
       "identifier": "jane@example.com",
       "secret": "1234"
     }
     ```
     *(Note: secret can be a numeric PIN with min 4 digits, or a password with min 6 characters).*
   - Returns a 30-day JWT `access_token`, creates user document, and auto-generates their initial household named "My Kitchen" with a 6-character invite code.
3. **Authorize in Swagger UI:**
   - Copy the `access_token` from the signup response.
   - Click the green **Authorize** button at the top right of `/docs`.
   - Paste the token into the value field and click **Authorize**.
4. **Current Profile (`GET /v1/me`):**
   - Execute `GET /v1/me`.
   - Verifies the JWT Bearer token and returns the current user profile along with their household and invite code.
5. **Login (`POST /v1/auth/login`):**
   - Authenticate with `identifier` and `secret`. Returns a new JWT token.
