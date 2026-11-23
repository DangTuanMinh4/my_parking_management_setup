# Dispatch Task — Worker 2 (UI Lucide Icon Standardization)

## Role & Mission
You are a teamwork_worker implementing Milestone 2: UI Lucide Icon Standardization across Parking Lot Management sub-components.

## Working Directory
`e:\code\parking_management\.agents\teamwork\teamwork_worker_m2\`

## Inputs & Context
- Read `e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md`.
- Read `e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md`.
- Read `e:\code\parking_management\.agents\teamwork\teamwork_explorer_survey_2\handoff.md` and `analysis.md` (contains the exact line-by-line replacement mapping!).

## Write Ownership (EXCLUSIVELY YOURS)
- `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStatsCards.jsx`
- `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotFilters.jsx`
- `parking_management_frontend/src/components/ParkingLotManagement/ParkingSlotMatrix.jsx`
- `parking_management_frontend/src/components/ParkingLotManagement/SlotDetailPanel.jsx`
- `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStructureAndActivity.jsx`
- DO NOT touch `ParkingLotManagement.jsx` or any service files (handled by other subagents).

## Strict Constraints
- STRICT BACKEND CODE LOCK: DO NOT modify any code or files in `parking_management_backend/`.
- STRICT ENV PRIVACY LOCK: DO NOT inspect or read real `.env` secret files.
- MANDATORY INTEGRITY WARNING:
  DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Requirements
1. **Standardize all icons to `lucide-react`**:
   - `ParkingLotStatsCards.jsx`: Replace raw SVGs with `LayoutGrid`, `CheckCircle2`, `Car`, `Clock`.
   - `ParkingLotFilters.jsx`: Replace raw SVGs with `Search`, `RotateCcw`, `Pencil`. Add view mode toggle buttons using `LayoutGrid` and `List` from `lucide-react` supporting `viewMode` ("matrix" | "list") and `setViewMode` / `onToggleViewMode` props.
   - `ParkingSlotMatrix.jsx`: Replace `✓` with `Check`, `🚗` with `Car`, `⏱` with `Clock`, `⚠️` with `Wrench`, lane arrows with `ArrowRight` / `ArrowLeft`. Ensure `isSelected` ring styling applies to `MAINTENANCE` slots as well.
   - `SlotDetailPanel.jsx`: Replace `✏️` with `Pencil`, `🗑️` with `Trash2`, status dots with semantic Lucide icons (`CheckCircle2`, `Car`, `Clock`, `Wrench`). Wire up the buttons to call props `onUpdateStatus`, `onEditSlot`, `onDeleteSlot` if provided.
   - `ParkingLotStructureAndActivity.jsx`: Replace `⚙` with `Settings`, add `Pencil` and `Trash2` to action buttons.
2. **ESLint & Component Cleanliness**:
   - Remove unused `import React from "react";` in all 5 files to resolve ESLint errors.
   - In `ParkingSlotMatrix.jsx`: Do NOT export `renderSlotCard` directly alongside the default export (either make it internal or keep only the component export) to satisfy React Refresh rule.
3. Verification:
   - Run `npm run build` and `npm run lint` in `parking_management_frontend`. Ensure clean build and that lint errors in your 5 files are resolved.
   - Deliver your handoff report to `handoff.md` in your working directory and notify the orchestrator.

## 2026-11-04T13:51:05Z
Received task from parent 56b281bd-5651-4f01-b1aa-31010383d653:
Implement Milestone 2: UI Lucide Icon Standardization across Parking Lot Management sub-components.
Write ownership:
- parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStatsCards.jsx
- parking_management_frontend/src/components/ParkingLotManagement/ParkingLotFilters.jsx
- parking_management_frontend/src/components/ParkingLotManagement/ParkingSlotMatrix.jsx
- parking_management_frontend/src/components/ParkingLotManagement/SlotDetailPanel.jsx
- parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStructureAndActivity.jsx
Constraints: STRICT BACKEND CODE LOCK, STRICT ENV PRIVACY LOCK, Remove unused React imports, Fix React Refresh in ParkingSlotMatrix.jsx, npm run build and npm run lint verify, deliver handoff.md and send_message.
