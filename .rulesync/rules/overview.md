---
root: true
targets: ["*"]
description: "Parking Management Workspace Router & Core Operating Principles"
---

# Parking Management Workspace Router

Monorepo root for Smart Mobility Parking Lot Management System (`Bãi xe Smart Mobility`).
Contains two independent sub-projects:
- `parking_management_backend/`: Django 6.1.2 + PostgreSQL 18.6 REST API service.
- `parking_management_frontend/`: React 19 + Vite web client.

---

## 1. Operating Principles & Safety Guardrails

1. **Disciplined Coding & Surgical Changes**:
   - **Surgical Edits**: Touch only what you must. Do not refactor adjacent code or reformat styling unless requested.
   - **Simplicity First**: Implement the minimal code that cleanly solves the problem.
   - **Goal-Driven & Verification**: Every change must be verified (lint, build, or tests). Refer to skill `disciplined-coding-workflow`.

2. **Project Integrity & Guardrails**:
   - **STRICT BACKEND CODE LOCK**: Backend do team khác phụ trách. Tuyệt đối KHÔNG sửa đổi, thêm mới, xóa hay can thiệp bất kỳ file nào trong `parking_management_backend/`. Chỉ đọc tài liệu/specs (`docs/`, `db/`) để mapping API lên Frontend khi cần.
   - **STRICT ENV PRIVACY LOCK**: NEVER inspect, read, display, or tool-read real `.env` secret files (`.env`, `.env.local`, `.env.production`). Only `.env.example` templates are permitted.
   - **STRICT GIT SAFETY GUARD**: Absolute ban on destructive git commands (`git push --force`, `git reset --hard`, `git clean -fdx`, `git checkout .`, `git push --delete`, `git branch -D`, `git prune/gc`). Follow `.rulesync/rules/git-safety-guard.md`.

3. **Context & Token Optimization**:
   - **Targeted Reads Only**: Avoid recursive scans (`Get-ChildItem -Recurse`, `tree`) or mass reads (> 250 lines). Use targeted line ranges or `Select-String`.
   - **Architecture & Cross-Project Resolution**: Use `codebase-graph-query` skill or `graphify-out/graph.json` (`graphify query ...`) instead of opening multiple files across projects.
   - **Frontend Modular Standards**: Follow `.rulesync/skills/frontend-modular-clean-code` for React components (< 200 lines, custom hooks < 120 lines, shared components from `components/common/`).

---

## 2. On-Demand Documentation Index

When deep domain context is required, read target files directly:

- **Run & Setup**: `02-run-backend-and-frontend.md`, `docker-compose.yml`, `Taskfile.yml`
- **Backend Specs & APIs** (`parking_management_backend/`):
  - API Catalog: `docs/api-endpoints.md`, `docs/guides/01-frontend-api-guide.md`
  - SRS & Decisions: `docs/requirements/06-frontend-srs-db-alignment.md` (TL-01 to TL-49), `07-fe-srs-traceability.md`, `03-delete-rules-catalog.md`
  - DB Schema: `db/01-schema.sql` (PostgreSQL 18.6 schema)
- **Frontend Specs & Design** (`parking_management_frontend/`):
  - Architecture & SRS: `docs/01-architecture.md`, `docs/02-srs.md`, `docs/03-business-flows.md`
  - Coding & Tests: `docs/04-coding-convention.md`, `docs/05-testing.md`
  - Design Tokens: `docs/design-system/`
