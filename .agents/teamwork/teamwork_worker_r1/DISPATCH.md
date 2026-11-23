## 2026-11-05T19:24:32Z
You are Worker 1 (Frontend Implementation Specialist) on a high-reliability engineering team.
Your working directory is: e:\code\parking_management\.agents\teamwork\teamwork_worker_r1\
Original request file: e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md
Project specification: e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md
Explorer handoff reports to read:
- e:\code\parking_management\.agents\teamwork\explorer_survey_r1\handoff.md
- e:\code\parking_management\.agents\teamwork\explorer_survey_r2\handoff.md
- e:\code\parking_management\.agents\teamwork\explorer_survey_r3\handoff.md

Domain skills to follow:
- e:\code\parking_management\.agents\skills\frontend-modular-clean-code\SKILL.md
- e:\code\parking_management\.agents\skills\disciplined-coding-workflow\SKILL.md
- e:\code\parking_management\.agents\skills\resilient-testing-workflow\SKILL.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

CRITICAL HARD CONSTRAINTS:
1. STRICT BACKEND CODE LOCK: DO NOT touch or modify any file in parking_management_backend/. Only work within parking_management_frontend/.
2. STRICT GIT SAFETY: DO NOT run destructive git commands (no git checkout, git reset, git restore).
3. STRICT BOUNDARY ("Tìm xe"): DO NOT modify src/pages/ParkingLotManagement.jsx or any file under src/components/ParkingLotManagement/.
4. STRICT ENV PRIVACY: Never inspect or read real .env files.
5. AI CLEAN CODE: No magic numbers, explicit booleans, no mock confidence values, component size < 200 lines where possible, proper UTF-8 preservation.

SCOPE & WORK ITEMS:
1. Create `src/components/VehicleManagement/scanPlate/ScanPlateImageUpload.jsx`:
   - Clean drag & drop + file picker for images (`image/png`, `image/jpeg`, `image/webp`).
   - Image preview thumbnail + "Chọn ảnh khác" button.
   - Calls `plateScanService.scanPlateImage(file, gateId)` on upload.
   - Loading indicator during scan, localized error alert on failure.
   - Callback `onImageScanned(scanResult, previewUrl)` to pass result to parent modal.
   - Keep under 180 lines, modular and clean.

2. Create `src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx`:
   - Unified card displaying the 5 canonical fields whenever a vehicle is matched or in system:
     1. Tên xe (`matchedVehicle?.model || matchedVehicle?.model_name || "—"`)
     2. Hãng xe (`matchedVehicle?.brand || "—"`)
     3. Tên khách hàng (`matchedVehicle?.customer?.name || matchedVehicle?.customerName || "Khách vãng lai"`)
     4. Số điện thoại (`matchedVehicle?.customer?.phone || matchedVehicle?.customerPhone || "—"`)
     5. Vị trí đỗ (`matchedVehicle?.parkingSlot?.display || matchedVehicle?.parkingSlot?.slot || matchedVehicle?.slotCode || "Chưa có vị trí"`)
   - Also displays ticket type badge and AI confidence pill (using actual confidence from `scanDetails.confidence` if present, never hardcoded).
   - Clean UI layout with clear labels and icons.

3. Update `src/components/VehicleManagement/ScanPlateModal.jsx`:
   - Add scan source toggle: `Quét Camera trực tiếp` vs `Tải ảnh từ file` (state `scanSourceMode`).
   - If camera: render `<ScanPlateCameraFeed />`. If image: render `<ScanPlateImageUpload />`.
   - Fix Camera Auto-Detect: Destructure `detectedData` and `scanState` from `usePlateAutoDetect`. Add `useEffect` on `detectedData?.plate_final` to auto-fill `detectedPlate`, trigger `handleMatchPlate(plate)`, and update `scanDetails`.
   - Handle image upload scan result: auto-fill `detectedPlate`, trigger `handleMatchPlate` or map vehicle, and update `scanDetails`.
   - Include `onCheckInSuccess` in prop signature and call it when check-in succeeds.
   - In success banners or footer: add action link `"Xem lịch sử đối soát →"` navigating to `/history?license_plate=${encodeURIComponent(detectedPlate)}` (and closing modal).
   - Preserve `"Xem hồ sơ chi tiết phương tiện →"` calling `handleApplySelection()` which invokes `onVehicleMatched(matchedVehicle)` to auto-paste into `VehicleManagement` search filter.

4. Update `src/components/VehicleManagement/scanPlate/EntryLanePanel.jsx` & `ExitLanePanel.jsx`:
   - Embed `<VehicleMatchedInfoCard matchedVehicle={matchedVehicle} scanDetails={scanDetails} />` in `EntryLanePanel.jsx` (replacing ad-hoc lines).
   - Embed `<VehicleMatchedInfoCard matchedVehicle={matchedVehicle} scanDetails={scanDetails} />` in `ExitLanePanel.jsx` above timestamps/fee so exit lane operators have full parity and see all 5 vehicle fields.

5. Update `src/components/VehicleManagement/GateCameraControlModal.jsx`:
   - Mirror the camera auto-detect fix so top header gate camera modal also auto-detects plates.

6. Update `src/hooks/useParkingHistory.js`:
   - Support `useSearchParams` from `react-router-dom`: if `license_plate` or `plate` is present in searchParams on mount, initialize or update `licensePlate` filter state and trigger session fetch for that plate.

7. Tests & Verification:
   - Add/update unit tests in `parking_management_frontend/tests/vehicleManagement.test.mjs` (e.g. `VEHICLE-16`, `VEHICLE-17`, `VEHICLE-18`) testing image scan mapping, 5 fields display, and camera auto-detection.
   - Add/update unit test in `parking_management_frontend/tests/parkingHistory.test.mjs` verifying history query param filtering.
   - Run unit tests: `npm --prefix parking_management_frontend run test:unit`. All tests MUST pass.
   - Run production build: `npm --prefix parking_management_frontend run build`. Must exit with 0.
   - Run git diff check: verify NO backend files and NO `ParkingLotManagement` files were modified.

8. Deliver report:
   - Write `handoff.md` in your working directory with Observation, Logic Chain, Changes Made, Test & Build Outputs, Verification Commands.
   - Send completion message to orchestrator.
