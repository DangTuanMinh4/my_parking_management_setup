# Parking Management System

Full-stack parking management system with Django REST API backend and React/Vite frontend.

## Quick Start

### Prerequisites
- Docker Desktop
- Task (taskfile.dev) - optional but recommended
- Node.js 22+ (for frontend development)
- Python 3.14+ (for backend development)

### Using Task (Recommended)

```bash
# Start database and backend
task dev

# In another terminal, start frontend
task frontend:dev

# Check status
task status

# Stop everything
task down
```

### Using Docker Compose (Full Stack)

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your values

# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Manual Development

See [02-run-backend-and-frontend.md](02-run-backend-and-frontend.md) for detailed manual instructions.

## Service URLs

| Service | URL |
|---------|-----|
| Frontend | http://127.0.0.1:5173 (or 5174) |
| Backend API | http://127.0.0.1:8000 |
| API Health | http://127.0.0.1:8000/api/health/ |
| Swagger UI | http://127.0.0.1:8000/api/docs/ |
| OpenAPI Schema | http://127.0.0.1:8000/api/schema/ |

## Default Test Account

Email: `hoang.dinh.khang@example.com`
Password: Set via `task dev:set-password`
To set password non-interactively: `task dev:set-password -- PW=testpass123`
Replace testpass123 with your desired local development password

## Project Structure

```
parking_management/
├── parking_management_backend/   # Django REST API
├── parking_management_frontend/  # React + Vite
├── Taskfile.yml                  # Task automation
├── docker-compose.yml            # Full stack Docker
├── .env.example                  # Environment template
└── 02-run-backend-and-frontend.md
```

## Common Tasks

```bash
# Backend
task backend:up        # Start backend container
task backend:logs      # View backend logs
task backend:health    # Check health endpoint
task lint:backend      # Lint backend code
task test:backend      # Run backend tests

# Frontend
task frontend:install  # Install dependencies
task frontend:dev      # Start dev server
task frontend:build    # Production build
task lint:frontend     # Lint frontend code

# Database
task db:up             # Start PostgreSQL
task db:down           # Stop PostgreSQL
task db:logs           # View database logs
```