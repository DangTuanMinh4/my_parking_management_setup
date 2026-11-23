# Handoff Report — Challenger 2 (State Machine & Flow Challenger)

**Working Directory**: `e:\code\parking_management\.agents\teamwork\challenger_v2\`  
**Target Repository**: `parking_management_frontend/`  
**Date**: 2026-11-05T19:52:00Z  
**Agent**: Challenger 2 (Empirical State Machine & Flow Challenger)  
**Recipient**: Orchestrator (`d867b49c-6937-4ba4-9c23-b96b03e107b6`)  
**Type**: Hard Handoff  
**Verdict**: **`REJECT`** (Blocking business logic defect in ticket badge state + lane parity discrepancy)

---

## 1. Observation

### 1.1 Direct Baseline Observations & Test Suite Execution
1. **Unit Test Suite**:
   Command: `npm --prefix parking_management_frontend run test:unit`
   Result: **82 passed, 0 failed, duration: ~1.3s**.
   - Tests `VEHICLE-16`, `VEHICLE-17`, `VEHICLE-18`, and `HISTORY-08` pass at the pure mapper and hook level.
2. **Production Build**:
   Command: `npm --prefix parking_management_frontend run build`
   Result: **Exited with code 0 in 17.43s**. Bundle transformed 2325 modules without syntax or import errors.
3. **Git & Boundary Verification**:
   - Zero modifications to `parking_management_backend/`.
   - Zero modifications to `src/pages/ParkingLotManagement.jsx` and `src/components/ParkingLotManagement/` ("Tìm xe" boundary preserved).

### 1.2 Direct Observations of Confirmed Defects

#### Defect 1: False Positive "Vé tháng hiệu lực" for Casual Walk-in Vehicles (Critical Logic Flaw)
- **Location**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx:29-34`
  ```javascript
  29:   const isTicketActive =
  30:     hasValidTicket ||
  31:     matchedVehicle?.ticketState === "active" ||
  32:     matchedVehicle?.ticket?.is_valid ||
  33:     Boolean(matchedVehicle?.ticket?.type);
  ```
- **Location**: `parking_management_frontend/src/utils/parking/plateScanMapper.js:125-136`
  ```javascript
  125: function extractTicket(rawTicket = {}, source = {}, hasPlate = false) {
  126:   const defaultFallbackType = hasPlate
  127:     ? MAPPER_DEFAULTS.DEFAULT_TICKET_TYPE
  128:     : MAPPER_DEFAULTS.UNREGISTERED_CUSTOMER;
  129: 
  130:   const ticketType =
  131:     source.ticket_type ||
  132:     rawTicket.package_name ||
  133:     rawTicket.ticket_type_name ||
  134:     rawTicket.type_display ||
  135:     defaultFallbackType;
  ```
  `MAPPER_DEFAULTS.DEFAULT_TICKET_TYPE` is `"Vé lượt"` (`plateScanMapper.js:12`).
- **Verbatim Empirical Test Output**:
  ```text
  walkInVehicle.ticket: { type: 'Vé lượt', status: 'none', effectiveTo: null }
  isTicketActive calculated: true
  displayedBadge in VehicleMatchedInfoCard: Vé tháng hiệu lực
  BUG_CONFIRMED: Walk-in vehicle is falsely displayed as Ve thang hieu luc!
  ```
- **Consequence**: For any casual walk-in vehicle (which has no contract or ticket in the system), `plateScanMapper` defaults `ticket.type` to `"Vé lượt"`. In `VehicleMatchedInfoCard.jsx`, line 33 evaluates `Boolean("Vé lượt") === true`. As a result, the card prominently renders the green badge **"Vé tháng hiệu lực"** (`bg-emerald-100 text-emerald-800`), misleading gate operators into believing an unregistered casual car has a valid monthly prepaid subscription!

#### Defect 2: Lane Parity Gap — `hasValidTicket` Prop Missing in `ExitLanePanel`
- **Location**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx:11-25`
  ```javascript
  11: export default function ExitLanePanel({
  12:   detectedPlate,
  13:   matchedVehicle,
  14:   rawLookup,
  15:   scanDetails,
  16:   exitFeeCalc,
  17:   calculatedDurationMinutes,
  18:   isFeeExempt,
  19:   setIsFeeExempt,
  20:   paymentMethod,
  21:   setPaymentMethod,
  22:   isActionPending,
  23:   onConfirmExit,
  24: }) {
  ```
- **Comparison with `EntryLanePanel.jsx:12-29`**:
  `EntryLanePanel` accepts `hasValidTicket` and passes it:
  `<VehicleMatchedInfoCard matchedVehicle={matchedVehicle} scanDetails={scanDetails} hasValidTicket={hasValidTicket} ... />`.
- In `ExitLanePanel.jsx:28-32`:
  ```javascript
  28:       <VehicleMatchedInfoCard
  29:         matchedVehicle={matchedVehicle}
  30:         scanDetails={scanDetails}
  31:         title="Thông tin phương tiện ra"
  32:       />
  ```
  `hasValidTicket` is neither accepted nor passed, causing an architectural asymmetry between Entry and Exit lanes.

#### Defect 3: Hardcoded Placeholder & Magic Number Contradiction on Exit Lane
- **Location**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx:44-50`
  ```javascript
  44:               {rawLookup?.open_session?.entry_time
  45:                 ? new Date(rawLookup.open_session.entry_time).toLocaleTimeString("vi-VN", {
  46:                     hour: "2-digit",
  47:                     minute: "2-digit",
  48:                   })
  49:                 : "08:00"}
  ```
- **Location**: `parking_management_frontend/src/components/VehicleManagement/ScanPlateModal.jsx:318-321`
  ```javascript
  318:   const rawEntryTime = rawLookup?.open_session?.entry_time;
  319:   const calculatedDurationMinutes = rawEntryTime
  320:     ? Math.max(15, Math.floor((Date.now() - new Date(rawEntryTime).getTime()) / 60000))
  321:     : 150;
  ```
- **Empirical Scenario**: When a vehicle exits without an open entry session in the database (or if lookup fails), `ExitLanePanel` renders:
  - Giờ vào: `"08:00"` (hardcoded fallback)
  - Giờ ra: Current time (e.g. `"19:30"`)
  - Thời lượng: `"2h 30m"` (from hardcoded `150` minutes)
  8:00 to 19:30 is 11 hours 30 minutes, yet the card displays 2h 30m. This directly violates AI Clean Code Rule 1 (Zero Magic Numbers & Fallbacks) and Rule 2 (No Mock/Hard-coded Business Values).

---

## 2. Logic Chain

1. **State Machine Analysis of Flow 1 (Live Camera) & Flow 2 (Image OCR)**:
   - When a vehicle plate is detected via camera (`usePlateAutoDetect`) or uploaded via file (`ScanPlateImageUpload`), the plate string is extracted and passed to `handleMatchPlate(plate)`.
   - If the vehicle is unregistered (walk-in), `mapPlateScanToVehicle` outputs `{ model: "Xe vãng lai", brand: "—", customer: { name: "Khách vãng lai" }, parkingSlot: { display: "Chưa có vị trí" }, ticket: { type: "Vé lượt", status: "none" } }`.
   - When this object is passed to `VehicleMatchedInfoCard`, the component checks `isTicketActive = hasValidTicket || ... || Boolean(matchedVehicle?.ticket?.type)`.
   - Because `matchedVehicle.ticket.type` is `"Vé lượt"` (a truthy non-empty string), `isTicketActive` becomes `true`.
   - The UI then displays `"Vé tháng hiệu lực"` (green badge) for an unregistered casual car.
   - At the Exit Lane, this creates a direct financial and operational contradiction: the card badge indicates a valid prepaid monthly ticket, but the billing section below calculates and requests an hourly fee (e.g., 25,000 VND). Operators cannot tell if the customer is being erroneously charged or if the vehicle actually has a subscription.

2. **Flow 3 (Auto-Paste Flow)**:
   - Preserved correctly. In `ScanPlateModal.jsx:299-304`, `handleApplySelection` invokes `onVehicleMatched(matchedVehicle)`. In `VehicleManagement.jsx:162-179`, `handleVehicleMatchedFromScan` updates `filters.search = plateToSearch`, sets `selectedVehicleId`, resets `currentPage` to 1, and scrolls to `#vehicle-detail-section`.
   - This flow satisfies Requirement R2 without regressions.

3. **Flow 4 (Scan-to-History Bridge)**:
   - Preserved correctly. Clicking `"Xem lịch sử đối soát →"` invokes `navigate('/history?license_plate=${encodeURIComponent(plateParam)}')`.
   - `useParkingHistory.js:16-19` extracts `searchParams.get("license_plate")`, syncs `licensePlate` state, and queries `getParkingSessions`.
   - Empirical test verified special characters (e.g. slashes and spaces) are safely encoded and decoded.

4. **Lane Parity Assessment**:
   - Parity is achieved for the 5 canonical fields via `VehicleMatchedInfoCard` in both panels.
   - However, `ExitLanePanel` lacks the `hasValidTicket` prop, and both panels suffer from the false positive badge defect. Furthermore, the `"08:00"` hardcoded entry time in `ExitLanePanel` creates unrealistic and conflicting UI states during unlinked exits.

---

## 3. Caveats

1. Physical camera hardware was not verified with real USB/RTSP streams because testing runs in a headless environment; however, `usePlateAutoDetect` was verified with synthetic candidate streams and test harnesses.
2. In `VehicleManagement.jsx`, searching for an unregistered walk-in vehicle (`WALK_IN_*`) correctly yields an empty table state ("Không tìm thấy phương tiện nào phù hợp với bộ lọc"). This is expected business logic since walk-ins have no contract record in the database.

---

## 4. Conclusion & Explicit Verdict

### **VERDICT: `REJECT`**

The implementation succeeds on build, unit tests, and layout boundaries, but contains **one critical business logic defect** and **two parity/code hygiene defects** that must be resolved before production approval:

1. **CRITICAL FIX**: In `VehicleMatchedInfoCard.jsx:29-34`, fix `isTicketActive` so it only activates for legitimate active tickets:
   ```javascript
   // Change from:
   const isTicketActive =
     hasValidTicket ||
     matchedVehicle?.ticketState === "active" ||
     matchedVehicle?.ticket?.is_valid ||
     Boolean(matchedVehicle?.ticket?.type);

   // To:
   const isTicketActive =
     hasValidTicket ||
     matchedVehicle?.ticketState === "active" ||
     matchedVehicle?.ticket?.is_valid ||
     (Boolean(matchedVehicle?.ticket?.type) &&
       matchedVehicle?.ticket?.type !== "Vé lượt" &&
       matchedVehicle?.ticket?.status === "active");
   ```
2. **PARITY FIX**: In `ExitLanePanel.jsx` and its invocations in `ScanPlateModal.jsx` and `GateCameraControlModal.jsx`, add `hasValidTicket={hasValidTicket}` to props and forward it to `VehicleMatchedInfoCard`.
3. **CLEAN CODE FIX**: In `ExitLanePanel.jsx:49`, replace hardcoded `"08:00"` with `"Chưa rõ giờ vào"` or `"Không có phiên"` when `rawLookup?.open_session?.entry_time` is absent.

---

## 5. Verification Method

### 5.1 Empirical Ticket Badge Stress Test
Execute the following verification command to check the defect and verify any future fix:
```powershell
node -e "
import('./parking_management_frontend/src/utils/parking/plateScanMapper.js').then((m) => {
  const walkInScan = {
    license_plate: '51K-123.45',
    plate_final: '51K-123.45',
    confidence: 88,
    vehicle_lookup: null
  };
  const walkInVehicle = m.mapPlateScanToVehicle(walkInScan);
  const isTicketActive =
    false ||
    walkInVehicle?.ticketState === 'active' ||
    walkInVehicle?.ticket?.is_valid ||
    Boolean(walkInVehicle?.ticket?.type);
  console.log('Current Badge Result:', isTicketActive ? 'FAIL: Ve thang hieu luc' : 'PASS: Ve luot vang lai');
});
"
```
**Expected after fix**: `PASS: Ve luot vang lai`.

### 5.2 Unit Test & Production Build Suite
```powershell
npm --prefix parking_management_frontend run test:unit
npm --prefix parking_management_frontend run build
```
Confirms all 82 existing unit tests pass and Vite build completes with exit code `0`.
