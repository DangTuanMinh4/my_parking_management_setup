## 2026-11-05T20:05:58Z
You are Worker R2 (Remediation Implementation Specialist) on a high-reliability engineering team.
Your working directory is: e:\code\parking_management\.agents\teamwork\teamwork_worker_r2\
Original request file: e:\code\parking_management\.agents\teamwork\ORIGINAL_REQUEST.md
Project specification: e:\code\parking_management\.agents\teamwork\orchestrator\PROJECT.md
Remediation blueprint to follow: e:\code\parking_management\.agents\teamwork\explorer_remediation_r2\handoff.md

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
5. AI CLEAN CODE: No magic numbers, explicit booleans, no mock confidence values, component size < 200 lines where practical, proper UTF-8 preservation.

SCOPE & IMPLEMENTATION STEPS (Follow `explorer_remediation_r2/handoff.md § 4`):
1. Step 1: In `src/utils/parking/plateScanMapper.js`, add and export `isVehicleTicketActive(matchedVehicle, hasValidTicket = false)`.
2. Step 2: In `src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx`, use `isVehicleTicketActive(matchedVehicle, hasValidTicket)`.
3. Step 3: In `src/utils/parking/parkingFeeCalculator.js`, support both `hasActiveTicket` and `hasValidTicket`.
4. Step 4: In `src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx`, add `hasValidTicket = false` prop and forward it to `VehicleMatchedInfoCard`. Replace hardcoded `"08:00"` fallback with `const UNKNOWN_ENTRY_TIME_LABEL = "Chưa rõ giờ vào"`. Format duration cleanly.
5. Step 5: In `src/components/VehicleManagement/ScanPlateModal.jsx`:
   - In `handleMatchPlate`: if `lookupResult?.open_session` is missing (e.g. 404 for casual walk-in cars), query `getParkingSessions({ license_plate: rawInput, status: 'open' })` to retrieve the active check-in session.
   - In `handleConfirmEntry`: extract and pass `imageUrl: entryImageUrl` into `checkInVehicle` so entry photos are saved in history. Update `rawLookup` with the new open session.
   - Compute real duration: `Math.max(1, Math.floor((Date.now() - new Date(rawEntryTime).getTime()) / 60000))` instead of hardcoded 150.
   - Forward `hasValidTicket={hasValidTicket}` to `<ExitLanePanel>`.
6. Step 6: In `src/components/VehicleManagement/GateCameraControlModal.jsx`, apply identical fixes as Step 5.
7. Step 7: In `tests/vehicleManagement.test.mjs`, add unit test `VEHICLE-19` verifying walk-in vehicles receive "Vé lượt vãng lai" and do not receive false positive "Vé tháng hiệu lực".
8. Verification:
   - Run unit tests: `npm --prefix parking_management_frontend run test:unit`. All tests MUST pass.
   - Run production build: `npm --prefix parking_management_frontend run build`. Must exit with 0.
   - Run git boundary check: verify NO backend files and NO `ParkingLotManagement` files were modified.
   - Update AST: `graphify update .` (or verify graph).
9. Write `handoff.md` in your working directory and notify orchestrator.
