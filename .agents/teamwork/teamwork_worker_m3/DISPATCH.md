# Dispatch Task — Worker 3 (Interactive Features & Action Handlers)

## Role & Mission
You are a teamwork_worker implementing Milestone 3: Interactive Features, Filter Functionality, View Mode Switching, and Slot Action Handlers in `ParkingLotManagement.jsx`.

## Working Directory
`e:\code\parking_management\.agents\teamwork\teamwork_worker_m3\`

## Inputs & Context
- Read `e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md`.
- Read `e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md`.
- Read `e:\code\parking_management\.agents\teamwork\teamwork_explorer_survey_3\handoff.md` and `analysis.md`.
- Read `e:\code\parking_management\.agents\teamwork\teamwork_worker_m1\handoff.md` for hook specifications (`useParkingLot.js` and `parkingLotService.js`).
- Read `e:\code\parking_management\.agents\teamwork\teamwork_worker_m2\handoff.md` for updated sub-components and icon usages.

## Write Ownership (EXCLUSIVELY YOURS)
- `parking_management_frontend/src/pages/ParkingLotManagement.jsx`
- `parking_management_frontend/src/components/ParkingLotManagement/ParkingSlotListView.jsx` (NEW)
- `parking_management_frontend/src/components/ParkingLotManagement/index.js` (barrel export)
- Any needed modal helpers in `parking_management_frontend/src/components/ParkingLotManagement/` (e.g. `SlotActionModal.jsx` if needed).

## Strict Constraints
- STRICT BACKEND CODE LOCK: DO NOT modify any code or files in `parking_management_backend/`.
- STRICT ENV PRIVACY LOCK: DO NOT inspect or read real `.env` secret files.
- MANDATORY INTEGRITY WARNING:
  DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
- STRICT API MODE: Remove `fullParkingLotData` mock import. Use `useParkingLot` hook. When the API returns an error / HTTP 404, display a prominent Error Alert Banner with a Retry button and show a clear empty/error state. DO NOT fallback to mock data!

## Requirements
1. **Remove Mock Data & Integrate Real API Hook**:
   - In `ParkingLotManagement.jsx`, remove `import { fullParkingLotData } from "../mocks/parkingLotData";`.
   - Import `useParkingLot` from `../hooks/useParkingLot`.
   - Call `const { slots, isLoading, error, refetch, updateSlotStatus } = useParkingLot({ floor: selectedFloor, zone: selectedZone });`.
   - When `error` is truthy, render a prominent Error Alert Banner at the top of the workspace detailing the API status and providing a "Thử lại" button invoking `refetch()`.
2. **Dynamic Filter Synchronization & Full Reset**:
   - Synchronize `selectedFloor` and `selectedZone` so changing them filters or fetches the matching slots.
   - Update `handleResetFilters` to reset ALL filters: `searchQuery`, `statusFilter`, `vehicleTypeFilter`, `selectedFloor` (to default e.g. "B1"), and `selectedZone` (to default e.g. "A").
   - Update `hasActiveFilters` check accordingly.
3. **View Mode Switching (Matrix View vs List View)**:
   - Add state `const [viewMode, setViewMode] = useState("matrix");` (`"matrix"` | `"list"`).
   - Pass `viewMode` and `setViewMode` to `ParkingLotFilters`.
   - Implement `ParkingSlotListView.jsx` using `DataTable` or custom table component displaying slots with Columns: Mã ô (code), Vị trí (Floor/Zone/Row), Loại ô, Trạng thái (Badge), Biển số xe, Thời gian, Thao tác (Xem / Sửa / Đổi trạng thái).
   - Conditionally render `ParkingSlotMatrix` when `viewMode === "matrix"` and `ParkingSlotListView` when `viewMode === "list"`.
4. **Action Handlers for SlotDetailPanel**:
   - Pass `onUpdateStatus`, `onEditSlot`, and `onDeleteSlot` callbacks to `SlotDetailPanel`.
   - When user clicks quick status change or edit/delete:
     - Invoke `updateSlotStatus` or open a modal / toast notification using `useToast()`.
     - Update slot selection and parent slots state.
5. **Interactive PageHeader & Structure Buttons**:
   - Wire "Xuất báo cáo", "+ Thêm tầng", "+ Thêm khu", "+ Thêm ô đỗ xe" to meaningful actions (e.g. download CSV / mock export notification, open add modal, or toast alert).
   - Wire "Cấu hình", "Sửa", "Xóa" buttons in `ParkingLotStructureAndActivity` to toast / modal handlers.
6. **ESLint & Build Cleanliness**:
   - Ensure zero ESLint errors and warnings.
   - Run `npm run build` in `parking_management_frontend` to confirm exit code 0.
   - Deliver handoff report to `handoff.md` and notify parent.


## 2026-11-04T14:01:58Z
You are a teamwork_worker.
Your working directory is e:\code\parking_management\.agents\teamwork\teamwork_worker_m3\
Read e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md, e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md, and e:\code\parking_management\.agents\teamwork\teamwork_worker_m3\DISPATCH.md.
Also read e:\code\parking_management\.agents\teamwork\teamwork_worker_m1\handoff.md and e:\code\parking_management\.agents\teamwork\teamwork_worker_m2\handoff.md.

Task:
Implement Milestone 3: Interactive Features, Filter Functionality, View Mode Switching, and Slot Action Handlers in ParkingLotManagement.jsx.

Write ownership:
- parking_management_frontend/src/pages/ParkingLotManagement.jsx
- parking_management_frontend/src/components/ParkingLotManagement/ParkingSlotListView.jsx (NEW)
- parking_management_frontend/src/components/ParkingLotManagement/index.js (barrel export)
- Any modal helper if needed in parking_management_frontend/src/components/ParkingLotManagement/

Strict constraints:
- STRICT BACKEND CODE LOCK: DO NOT modify any code or files in parking_management_backend/.
- STRICT ENV PRIVACY LOCK: DO NOT inspect or read real .env secret files.
- MANDATORY INTEGRITY WARNING:
  DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
- STRICT API MODE: Remove fullParkingLotData mock import. Use useParkingLot hook. When the API returns an error / HTTP 404, display a prominent Error Alert Banner with a Retry button and show a clear empty/error state. DO NOT fallback to mock data!
- Standardize any icon in ParkingLotManagement.jsx to Lucide icons (e.g. Download for export report, Plus for add buttons, AlertTriangle / AlertCircle for error banner, RefreshCw for retry).
- Clean up any unused React imports or variables to keep ESLint clean.
- Run npm run build and npx eslint src/pages/ParkingLotManagement.jsx src/components/ParkingLotManagement to verify.
- Deliver your handoff report to handoff.md and notify the parent when done.
