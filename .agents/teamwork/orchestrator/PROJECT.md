# Project: License Plate Scan, Auto-fill, and History Display Integration

## Architecture
- **Target Repository**: `parking_management_frontend/` (React 19 + Vite + Tailwind CSS)
- **Protected Boundaries**:
  - `parking_management_backend/`: STRICT BACKEND LOCK (0 modifications permitted).
  - `src/pages/ParkingLotManagement.jsx` & `src/components/ParkingLotManagement/**`: STRICT "TÌM XE" BOUNDARY (DO-NOT-TOUCH).
- **Core Components & Data Flow**:
  1. `ScanPlateModal.jsx` (Modal orchestrator for plate scanning):
     - Toggle between `<ScanPlateCameraFeed />` and `<ScanPlateImageUpload />`.
     - Subscribes to `detectedData?.plate_final` from `usePlateAutoDetect`.
     - Handles image OCR results from `plateScanService.scanPlateImage(file, activeGateId)`.
     - Coordinates `handleMatchPlate(plate)` to lookup vehicle via API (`lookupVehicleByPlate`) and client store (`vehicles` from `useVehicleData`).
     - Passes `matchedVehicle` and `scanDetails` to `EntryLanePanel` and `ExitLanePanel`.
     - Provides `"Xem lịch sử đối soát →"` action navigating to `/history?license_plate=${plate}`.
     - Provides `"Xem hồ sơ chi tiết phương tiện →"` action calling `onVehicleMatched(matchedVehicle)` to auto-paste into `VehicleManagement` search filter.
  2. `ScanPlateImageUpload.jsx` (New modular component < 180 lines):
     - Drag & drop zone, file picker, preview thumbnail, loading spinner, error handling.
  3. `VehicleMatchedInfoCard.jsx` (New modular component ~100 lines):
     - Unified 5-field vehicle information card:
       - Tên xe (`vehicle.model`)
       - Hãng xe (`vehicle.brand`)
       - Tên khách hàng (`vehicle.customer?.name` / `customerName`)
       - Số điện thoại (`vehicle.customer?.phone` / `customerPhone`)
       - Vị trí đỗ (`vehicle.parkingSlot?.display` / `slotCode`)
     - Integrated in both `EntryLanePanel.jsx` and `ExitLanePanel.jsx`.
  4. `useParkingHistory.js` & `ParkingHistory.jsx`:
     - Reads `useSearchParams()` for `license_plate` or `plate` to pre-filter session history upon navigation.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Image Plate Scan UI & Handler | File upload & drag-drop UI calling `scanPlateImage(file, gateId)` in `ScanPlateModal` | M1 | ORIGINAL_REQUEST R1 |
| 2 | Camera Auto-Detect Bug Fix | Destructure `detectedData` and auto-fill `detectedPlate` in `ScanPlateModal` | M1 | ORIGINAL_REQUEST R1 |
| 3 | 5-Field Vehicle Info Display | Unified `VehicleMatchedInfoCard` showing Tên xe, Hãng xe, Khách hàng, SĐT, Vị trí đỗ in Entry & Exit lanes | M1 | ORIGINAL_REQUEST R1 |
| 4 | GateCameraControlModal Parity | Apply camera auto-detect fix to header gate camera modal | M1 | ORIGINAL_REQUEST R1 |
| 5 | Auto-fill / Paste Preservation | Maintain `onVehicleMatched` -> `handleVehicleMatchedFromScan` in `VehicleManagement` | M2 | ORIGINAL_REQUEST R2 |
| 6 | DO-NOT-TOUCH "Tìm xe" Boundary | Keep `ParkingLotManagement` and slot locator code completely untouched | M2 | ORIGINAL_REQUEST R2 |
| 7 | Branch `minh` Audit History Verification | Verified branch `minh` merged into HEAD via PR #32 with complete history & image modal | M3 | ORIGINAL_REQUEST R3 |
| 8 | History Navigation Bridge | Add button to navigate to `/history?license_plate=...` and read query params in `useParkingHistory` | M3 | ORIGINAL_REQUEST R3 |
| 9 | Entry/Exit Image Persistence in History | Pass `entry_image_url` / scan image into session check-in so camera photos display in Parking History | M5 | ORIGINAL_REQUEST Follow-up 1 |
| 10 | Real Entry Time & Real Duration in Checkout | Extract real `entry_time` from session for that plate, eliminate hardcoded 08:00 and 150m, compute live duration | M5 | ORIGINAL_REQUEST Follow-up 2 |
| 11 | Comprehensive Testing & Build Verification | Add unit tests for image scan, 5-field mapping, history query param; verify 0 lint and 0 build errors | M4 | ORIGINAL_REQUEST AC |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Image Scan & 5-Field Auto-fill | `ScanPlateImageUpload.jsx`, `VehicleMatchedInfoCard.jsx`, `ScanPlateModal.jsx`, `EntryLanePanel.jsx`, `ExitLanePanel.jsx`, `GateCameraControlModal.jsx` | none | DONE (Implemented & verified by Worker R1) |
| M2 | Auto-fill/Paste Preservation & Boundary | `VehicleManagement.jsx`, `VehicleFilters.jsx`, Boundary enforcement on `ParkingLotManagement` | M1 | DONE (Preserved & verified by Worker R1) |
| M3 | Scan-to-History Navigation Bridge | `useParkingHistory.js`, `ScanPlateModal.jsx` | M1 | DONE (Implemented & verified by Worker R1) |
| M5 | User Feedback & Gate Defect Remediation | `VehicleMatchedInfoCard.jsx`, `ExitLanePanel.jsx`, `ScanPlateModal.jsx`, `parkingSessionService.js`, `useParkingHistory.js` | M1, M2, M3 | IN_PROGRESS (Remediation Explorer active) |
| M4 | Comprehensive Verification & Auditing | Unit tests in `tests/vehicleManagement.test.mjs` & `tests/parkingHistory.test.mjs`, build, review, challenge, forensic audit | M1, M2, M3, M5 | PENDING_RE_AUDIT |

## Interface Contracts
### `ScanPlateImageUpload` ↔ `ScanPlateModal`
- Props:
  - `gateId`: number (active gate ID)
  - `onImageScanned`: `(scanResult: object, previewUrl: string) => void`
  - `disabled`: boolean

### `VehicleMatchedInfoCard` ↔ `EntryLanePanel` / `ExitLanePanel`
- Props:
  - `matchedVehicle`: object | null (contains `model`, `brand`, `customer: { name, phone }`, `parkingSlot: { display }`)
  - `scanDetails`: object | null (contains `confidence`, `plate`, `source`, `imageUrl`)

### `ScanPlateModal` ↔ `VehicleManagement`
- Props:
  - `onVehicleMatched`: `(matchedVehicle: object) => void`
  - `onCheckInSuccess`: `(session: object) => void`
  - Callback updates `filters.search = matchedVehicle.licensePlate` and selects vehicle.

### `ScanPlateModal` ↔ `ParkingHistory`
- Navigation contract:
  - URL: `/history?license_plate=${encodeURIComponent(licensePlate)}`
  - `useParkingHistory` extracts `searchParams.get("license_plate")` and initializes filter state.

## Code Layout
```
parking_management_frontend/
├── src/
│   ├── components/
│   │   ├── VehicleManagement/
│   │   │   ├── ScanPlateModal.jsx               [M1, M2, M3]
│   │   │   ├── GateCameraControlModal.jsx       [M1]
│   │   │   ├── scanPlate/
│   │   │   │   ├── ScanPlateImageUpload.jsx     [M1: NEW]
│   │   │   │   ├── VehicleMatchedInfoCard.jsx   [M1: NEW]
│   │   │   │   ├── EntryLanePanel.jsx           [M1]
│   │   │   │   ├── ExitLanePanel.jsx            [M1]
│   │   │   │   └── ScanPlateCameraFeed.jsx      [Preserved]
│   │   │   ├── VehicleFilters.jsx               [M2: Preserved]
│   │   │   └── PageSectionHeader.jsx            [Preserved]
│   │   └── ParkingHistory/                      [M3: Preserved from minh]
│   │       ├── ParkingHistoryTable.jsx
│   │       ├── ParkingImageModal.jsx
│   │       ├── ParkingSessionThumbnail.jsx
│   │       └── ParkingHistoryFilters.jsx
│   ├── pages/
│   │   ├── VehicleManagement.jsx                [M2: Preserved auto-paste]
│   │   ├── ParkingHistory.jsx                   [M3]
│   │   └── ParkingLotManagement.jsx             [DO NOT TOUCH: Boundary]
│   └── hooks/
│       ├── useParkingHistory.js                 [M3: add useSearchParams]
│       └── usePlateAutoDetect.js                [Preserved]
└── tests/
    ├── vehicleManagement.test.mjs               [M4: Add VEHICLE-16, 17, 18]
    └── parkingHistory.test.mjs                  [M4: Add HISTORY-08]
```
