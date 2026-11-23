# Dispatch Task — Worker 1 (Backend Contract & API Integration)

## Role & Mission
You are a teamwork_worker implementing Milestone 1: Backend Contract & API Integration for Parking Lot & Slot Management.

## Working Directory
`e:\code\parking_management\.agents\teamwork\teamwork_worker_m1\`

## Inputs & Context
- Read `e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md`.
- Read `e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md`.
- Read `e:\code\parking_management\.agents\teamwork\teamwork_explorer_survey_1\handoff.md` and `analysis.md`.
- Frontend API client: `parking_management_frontend/src/services/apiClient.js`.

## Write Ownership (EXCLUSIVELY YOURS)
- `parking_management_frontend/src/services/parkingLotService.js` (NEW)
- `parking_management_frontend/src/hooks/useParkingLot.js` (NEW)
- DO NOT touch any other source files.

## Strict Constraints
- STRICT BACKEND CODE LOCK: DO NOT modify any code or files in `parking_management_backend/`.
- STRICT ENV PRIVACY LOCK: DO NOT inspect or read real `.env` secret files.
- MANDATORY INTEGRITY WARNING:
  DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
- STRICT API MODE: No mock fallback when API calls fail! Capture HTTP 404 and network errors gracefully, store error details in state, return empty slots `[]`, and set `isLoading = false`.

## Requirements
1. `src/services/parkingLotService.js`:
   - Use `apiClient` to implement real backend calls:
     - `getSlots(params = {})`: `GET /api/v1/parking/slots/` (with query params e.g. floor, zone, status, vehicle_type).
     - `updateSlotStatus(slotId, data)`: `PATCH /api/v1/parking/slots/${slotId}/`.
     - `getActiveSessions()`: `GET /api/v1/parking/sessions/?status=open` (returns operational sessions).
   - Export these functions cleanly.
2. `src/hooks/useParkingLot.js`:
   - Accepts parameters `{ floor, zone }`.
   - Calls `parkingLotService.getSlots`.
   - Manages `{ slots, isLoading, error, refetch, updateSlotStatus }`.
   - In catch block: If backend responds with 404 (unbuilt endpoint) or network error, set `error` state (e.g. "Không thể kết nối API máy chủ (/api/v1/parking/slots/): Endpoint chưa được triển khai hoặc không phản hồi (HTTP 404)."), set `slots = []`. NEVER fall back to `src/mocks/parkingLotData.js`.
   - Implement `updateSlotStatus(slotId, newStatus)` which calls `parkingLotService.updateSlotStatus`, with error handling.
3. Verification:
   - Run `npm run build` in `parking_management_frontend` to ensure zero compilation or syntax errors.
   - Deliver your handoff report to `handoff.md` in your working directory and notify the orchestrator.


## 2026-11-04T13:50:26Z
You are a teamwork_worker.
Your working directory is e:\code\parking_management\.agents\teamwork\teamwork_worker_m1\
Read e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md, e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md, and e:\code\parking_management\.agents\teamwork\teamwork_worker_m1\DISPATCH.md.

Task:
Implement Milestone 1: Backend Contract & API Integration for Parking Lot & Slot Management.
Write ownership:
- parking_management_frontend/src/services/parkingLotService.js
- parking_management_frontend/src/hooks/useParkingLot.js

Strict constraints:
- STRICT BACKEND CODE LOCK: DO NOT modify any code or files in parking_management_backend/.
- STRICT ENV PRIVACY LOCK: DO NOT inspect or read real .env secret files.
- MANDATORY INTEGRITY WARNING:
  DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
- STRICT API MODE: No mock fallback when API calls fail! Capture HTTP 404 and network errors gracefully, store error details in state, return empty slots [], and set isLoading = false.
- Run npm run build in parking_management_frontend to verify compilation.
- Deliver your handoff report to handoff.md and notify the parent when done.
