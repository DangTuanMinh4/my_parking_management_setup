# Handoff Report — Remediation Explorer R2

**Working Directory**: `e:\code\parking_management\.agents\teamwork\explorer_remediation_r2\`  
**Target Repository**: `parking_management_frontend/`  
**Date**: 2026-11-05T20:05:00Z  
**Agent**: Remediation Explorer (`explorer_remediation_r2`)  
**Recipient**: Orchestrator (`d867b49c-6937-4ba4-9c23-b96b03e107b6`)  
**Type**: Hard Handoff (Investigation & Surgical Strategy Complete)  

---

## 1. Observation

### 1.1 Direct Baseline Observations & Root Cause Analysis

#### Defect 1: False Positive "Vé tháng hiệu lực" for Casual Walk-in Vehicles
- **File**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx:29-34`
  ```javascript
  29:   const isTicketActive =
  30:     hasValidTicket ||
  31:     matchedVehicle?.ticketState === "active" ||
  32:     matchedVehicle?.ticket?.is_valid ||
  33:     Boolean(matchedVehicle?.ticket?.type);
  ```
- **File**: `parking_management_frontend/src/utils/parking/plateScanMapper.js:12-25, 125-136`
  ```javascript
  12:   DEFAULT_TICKET_TYPE: "Vé lượt",
  ...
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
- **Direct Cause**: For unregistered walk-in vehicles, `plateScanMapper.js` defaults `ticket.type` to `"Vé lượt"`. In `VehicleMatchedInfoCard.jsx:33`, `Boolean("Vé lượt")` evaluates to `true`, causing line 71 to render the green badge `"Vé tháng hiệu lực"` (`bg-emerald-100 text-emerald-800`), misleading operators into believing a walk-in car has an active prepaid subscription.

#### Defect 2: Lane Parity Gap — `hasValidTicket` Missing in `ExitLanePanel`
- **File**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx:11-32`
  - `hasValidTicket` is omitted from props (lines 11-24).
  - `<VehicleMatchedInfoCard>` on line 28 is called with only `matchedVehicle`, `scanDetails`, and `title="Thông tin phương tiện ra"` without `hasValidTicket`.
- **Contrast with `EntryLanePanel.jsx:12-29, 48-53`**:
  - `EntryLanePanel` receives `hasValidTicket` in props and forwards `hasValidTicket={hasValidTicket}` to `VehicleMatchedInfoCard`.
- **Callers**:
  - `ScanPlateModal.jsx:639-653`: Renders `<ExitLanePanel>` without passing `hasValidTicket={hasValidTicket}`.
  - `GateCameraControlModal.jsx:539-553`: Renders `<ExitLanePanel>` without passing `hasValidTicket={hasValidTicket}`.

#### Defect 3: Hardcoded Placeholder & Default Duration Contradiction
- **File**: `parking_management_frontend/src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx:44-50`
  ```javascript
  44:               {rawLookup?.open_session?.entry_time
  45:                 ? new Date(rawLookup.open_session.entry_time).toLocaleTimeString("vi-VN", {
  46:                     hour: "2-digit",
  47:                     minute: "2-digit",
  48:                   })
  49:                 : "08:00"}
  ```
- **Files**:
  - `ScanPlateModal.jsx:318-321`: `calculatedDurationMinutes` defaults to `150` minutes when `rawLookup?.open_session?.entry_time` is absent.
  - `GateCameraControlModal.jsx:271-276`: `calculatedDurationMinutes` defaults to `150` minutes.
- **Direct Cause**: Violates AI Clean Code Rule 1 (Zero Magic Numbers & Fallback Placeholders) and Rule 2 (No Mock/Hard-coded Business Values). When exit lookup fails to link with open session, the UI renders `08:00`, current time `02:57`, and `Thời lượng: 2h 30m` (from 150m), generating a blatant time and accounting mismatch.

#### User Issue 1: Lỗi Không Lưu Ảnh Lịch Sử Ra Vào
- **Observation**: User reported: *"ảnh vẫn đang bị lỗi chưa lưu được vào lịch sử ra vào"*.
- **File**: `parking_management_frontend/src/components/VehicleManagement/ScanPlateModal.jsx:371-375`
  ```javascript
  371:       const checkInResult = await checkInVehicle({
  372:         licensePlate: detectedPlate || matchedVehicle?.licensePlate,
  373:         slotId: targetSlotId,
  374:         entryGateId: DEFAULT_ENTRY_GATE_ID,
  375:       });
  ```
- **File**: `parking_management_frontend/src/components/VehicleManagement/GateCameraControlModal.jsx:326-330`
  ```javascript
  326:       await checkInVehicle({
  327:         licensePlate: detectedPlate || matchedVehicle?.licensePlate,
  328:         slotId: targetSlotId,
  329:         entryGateId: DEFAULT_ENTRY_GATE_ID,
  330:       });
  ```
- **File**: `parking_management_frontend/src/services/parkingSessionService.js:206, 234, 262-264`
  ```javascript
  206: export async function checkInVehicle({ ..., imageUrl = null }) {
  ...
  234:       plateImageUrl: imageUrl || "https://images.unsplash.com/...",
  ...
  262:   if (imageUrl) {
  263:     payload.entry_image_url = imageUrl;
  264:   }
  ```
- **Direct Cause**: `checkInVehicle` expects `imageUrl`, but neither `ScanPlateModal` nor `GateCameraControlModal` passed `imageUrl` in the invocation payload! In real API mode, `payload.entry_image_url` is omitted entirely; in mock mode, it falls back to an unsplash placeholder. Consequently, the check-in record has no entry snapshot, causing `ParkingSessionThumbnail.jsx` and `ParkingImageModal.jsx` to show blank/placeholder.

#### User Issue 2: Lỗi Hiển Thị Giờ Vào & Thời Lượng Check-out (Check-in 02:49, Check-out 02:57 nhưng hiện 08:00 và 2h 30m)
- **Observation**: User tested check-in at 02:49, then checked out at 02:57. The checkout screen showed: `Giờ vào: 08:00`, `Giờ ra: 02:57`, `Thời lượng: 2h 30m`.
- **Direct Cause**:
  1. `lookupVehicleByPlate` queries `/api/v1/parking/vehicle-lookup/?license_plate=...`. For walk-in vehicles without a contract record in `vehicles` table, this endpoint returns `HTTP 404 Not Found` (`MSG-4.5.1-M01`).
  2. In `ScanPlateModal.jsx:206-225`, the `catch` block catches the 404 and creates a local fallback vehicle, but leaves `rawLookup` as `null`!
  3. Because `rawLookup` is `null`, `rawLookup?.open_session?.entry_time` is `undefined`.
  4. Line 49 in `ExitLanePanel.jsx` falls back to `"08:00"`, and line 321 in `ScanPlateModal.jsx` falls back to `150` minutes (`2h 30m`).
  5. The real active parking session created at 02:49 exists in `/api/v1/parking/sessions/?status=open&license_plate=...` (or in `mockParkingHistory`), but was never queried during plate matching!

---

## 2. Logic Chain

1. **Badge Logic Decoupling & Pure Extraction**:
   - `VehicleMatchedInfoCard` should not rely on raw JSX inline boolean logic for ticket activation.
   - We extract a pure helper function `isVehicleTicketActive(matchedVehicle, hasValidTicket = false)` in `src/utils/parking/plateScanMapper.js`.
   - Criteria for active ticket:
     - `hasValidTicket === true` (explicit assertion from caller/backend active ticket)
     - OR `matchedVehicle?.hasActiveTicket === true`
     - OR `matchedVehicle?.ticketState === "active"`
     - OR `matchedVehicle?.ticket?.is_valid === true`
     - OR (`matchedVehicle?.ticket?.type` exists AND `matchedVehicle?.ticket?.type !== "Vé lượt"` AND `matchedVehicle?.ticket?.status === "active"`)
   - Any vehicle with `ticket.type === "Vé lượt"` or `ticket.status === "none"` or `hasActiveTicket === false` evaluates to `false`.
   - `VehicleMatchedInfoCard` calls `isVehicleTicketActive(matchedVehicle, hasValidTicket)` and renders `"Vé lượt vãng lai"` (blue badge) when false, and `"Vé tháng hiệu lực"` (green badge) only when true.

2. **Exit Lane Parity**:
   - Adding `hasValidTicket = false` to `ExitLanePanel` props and passing `hasValidTicket={hasValidTicket}` to `VehicleMatchedInfoCard` restores 100% component symmetry between Entry and Exit lanes.
   - Updating `ScanPlateModal` and `GateCameraControlModal` ensures the computed `hasValidTicket` is forwarded to both `EntryLanePanel` and `ExitLanePanel`.

3. **Active Session Resolution for Walk-in Vehicles**:
   - When matching a plate in `handleMatchPlate`:
     - Attempt `lookupVehicleByPlate(rawInput)`.
     - If `lookupResult?.open_session` is missing or lookup fails (404 for casual cars), query active sessions via `getParkingSessions({ license_plate: rawInput, status: 'open' })`.
     - If an open session exists, populate `open_session` with `id`, `session_code`, `entry_time`, and `entry_image_url`.
     - When check-in succeeds in `handleConfirmEntry`, immediately update `rawLookup.open_session` with the newly created session.
   - In `ScanPlateModal` & `GateCameraControlModal`:
     - Calculate `calculatedDurationMinutes = rawEntryTime ? Math.max(1, Math.floor((Date.now() - new Date(rawEntryTime).getTime()) / 60000)) : 0`.
     - Eliminate the `150` minutes hardcoded default.
   - In `ExitLanePanel`:
     - Define `const UNKNOWN_ENTRY_TIME_LABEL = "Chưa rõ giờ vào";`.
     - If `rawLookup?.open_session?.entry_time` is absent, display `UNKNOWN_ENTRY_TIME_LABEL` and duration `" — "`.
     - If present, display the exact formatted entry time (e.g. `02:49`) and exact real duration (e.g. `8m`).
     - At 8 minutes, `calculateParkingFee` recognizes duration < 15 minutes and accurately applies `0đ (Miễn phí dưới 15 phút)`.

4. **History Image Preservation**:
   - In `handleConfirmEntry` (both `ScanPlateModal` and `GateCameraControlModal`):
     - Extract `entryImageUrl = scanDetails?.imageUrl || matchedVehicle?.imageUrl || detectedData?.image_url || detectedData?.plate_image_url || null`.
     - If null and `videoRef?.current` is active, capture frame snapshot as base64 data URL via canvas helper.
     - Pass `imageUrl: entryImageUrl` into `checkInVehicle({ licensePlate, slotId, entryGateId, imageUrl: entryImageUrl })`.
     - In both real API (`payload.entry_image_url`) and mock mode (`plateImageUrl`), the image is permanently stored in the session record and renders in `/history` and image comparison modals.

---

## 3. Caveats

1. Physical camera hardware was not verified with real RTSP streams due to headless runner environment; canvas snapshot and stream mock tests cover frame capture.
2. If a customer checks out a vehicle that truly has no entry session in the system (e.g. lost ticket or barrier force-open), duration is displayed as `—` and entry time as `Chưa rõ giờ vào`, prompting the operator to confirm or apply manual flat fee rather than displaying misleading 8:00 AM.
3. Node native test runner (`node --test`) does not transpile `.jsx` files without a bundler. Placing `isVehicleTicketActive` in `plateScanMapper.js` allows direct, lightning-fast testing in `tests/vehicleManagement.test.mjs`.

---

## 4. Conclusion & Surgical Implementation Blueprint for Worker R2

Worker R2 must execute the following 7 targeted file modifications:

### Step 1: Update `src/utils/parking/plateScanMapper.js`
Add and export `isVehicleTicketActive`:
```javascript
/**
 * isVehicleTicketActive: Kiểm tra trạng thái hiệu lực của vé phương tiện (Vé tháng / Vé đăng ký)
 * Ngăn chặn hoàn toàn false-positive đối với vé lượt hoặc xe vãng lai.
 */
export function isVehicleTicketActive(matchedVehicle, hasValidTicket = false) {
  if (Boolean(hasValidTicket)) return true;
  if (!matchedVehicle) return false;
  if (matchedVehicle.hasActiveTicket) return true;
  if (matchedVehicle.ticketState === "active") return true;
  if (matchedVehicle.ticket?.is_valid === true) return true;
  if (
    matchedVehicle.ticket?.type &&
    matchedVehicle.ticket?.type !== MAPPER_DEFAULTS.DEFAULT_TICKET_TYPE &&
    matchedVehicle.ticket?.status === "active"
  ) {
    return true;
  }
  return false;
}
```

### Step 2: Update `src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx`
1. Import `isVehicleTicketActive`:
   ```javascript
   import { isVehicleTicketActive } from "../../../utils/parking/plateScanMapper.js";
   ```
2. Replace lines 29-33:
   ```javascript
   const isTicketActive = isVehicleTicketActive(matchedVehicle, hasValidTicket);
   ```

### Step 3: Update `src/utils/parking/parkingFeeCalculator.js`
Support both `hasActiveTicket` and `hasValidTicket` in parameter destructuring:
```javascript
export function calculateParkingFee({
  vehicleType = "CAR",
  durationMinutes = 0,
  hasActiveTicket = false,
  hasValidTicket = false,
  isExempt = false,
}) {
  void vehicleType;
  const isTicketValid = Boolean(hasActiveTicket || hasValidTicket);
  if (isTicketValid || isExempt) {
    return {
      feeAmount: 0,
      feeFormatted: "0đ (Miễn phí / Vé tháng)",
      isCoveredByTicket: true,
      calculationBreakdown: isExempt
        ? "Được miễn cước (Đặc cách / Sự cố kỹ thuật)"
        : "Phương tiện đã đăng ký vé tháng còn hiệu lực",
      hoursBilled: 0,
    };
  }
```

### Step 4: Update `src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx`
1. Define constant at top:
   ```javascript
   const UNKNOWN_ENTRY_TIME_LABEL = "Chưa rõ giờ vào";
   ```
2. Add `hasValidTicket = false` to props signature:
   ```javascript
   export default function ExitLanePanel({
     detectedPlate,
     matchedVehicle,
     rawLookup,
     scanDetails,
     exitFeeCalc,
     calculatedDurationMinutes,
     isFeeExempt,
     setIsFeeExempt,
     paymentMethod,
     setPaymentMethod,
     isActionPending,
     onConfirmExit,
     hasValidTicket = false,
   }) {
   ```
3. Forward `hasValidTicket={hasValidTicket}` to `VehicleMatchedInfoCard`:
   ```jsx
   <VehicleMatchedInfoCard
     matchedVehicle={matchedVehicle}
     scanDetails={scanDetails}
     hasValidTicket={hasValidTicket}
     title="Thông tin phương tiện ra"
   />
   ```
4. Replace `"08:00"` fallback with `UNKNOWN_ENTRY_TIME_LABEL`, and format duration safely:
   ```jsx
   <div>
     <span className="text-slate-400 block text-3xs">Giờ vào</span>
     <span className="font-mono font-bold text-slate-800">
       {rawLookup?.open_session?.entry_time
         ? new Date(rawLookup.open_session.entry_time).toLocaleTimeString("vi-VN", {
             hour: "2-digit",
             minute: "2-digit",
           })
         : UNKNOWN_ENTRY_TIME_LABEL}
     </span>
   </div>
   <div>
     <span className="text-slate-400 block text-3xs">Giờ ra</span>
     <span className="font-mono font-bold text-slate-800">
       {new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" })}
     </span>
   </div>
   <div>
     <span className="text-slate-400 block text-3xs">Thời lượng</span>
     <span className="font-bold text-blue-700">
       {rawLookup?.open_session?.entry_time && calculatedDurationMinutes > 0
         ? Math.floor(calculatedDurationMinutes / 60) > 0
           ? `${Math.floor(calculatedDurationMinutes / 60)}h ${calculatedDurationMinutes % 60}m`
           : `${calculatedDurationMinutes % 60}m`
         : "—"}
     </span>
   </div>
   ```

### Step 5: Update `src/components/VehicleManagement/ScanPlateModal.jsx`
1. In `handleMatchPlate`:
   - Import `getParkingSessions` from `../../services/plateScanService.js`.
   - When `lookupResult?.open_session` is missing (e.g. 404 for walk-in car), query `getParkingSessions({ license_plate: rawInput, status: 'open' })`.
   - If an open session is found, populate `open_session` in `consolidatedLookup` with `id`, `session_code`, `entry_time`, `entry_image_url`, and `slot_code`.
2. In camera `useEffect`:
   - Include `imageUrl: detectedData?.image_url || detectedData?.plate_image_url || null` in `setScanDetails`.
3. In `handleConfirmEntry`:
   - Helper function `captureVideoSnapshot(videoEl)` to capture live camera frame as base64 JPEG data URL if image URL is null.
   - Extract `entryImageUrl = scanDetails?.imageUrl || matchedVehicle?.imageUrl || (videoRef?.current ? captureVideoSnapshot(videoRef.current) : null);`.
   - Pass `imageUrl: entryImageUrl` into `checkInVehicle`.
   - Update `rawLookup` with the new open session so switching immediately to Exit Lane retains the real entry time and image.
4. Duration calculation:
   - Change `calculatedDurationMinutes`:
     ```javascript
     const rawEntryTime = rawLookup?.open_session?.entry_time;
     const calculatedDurationMinutes = rawEntryTime
       ? Math.max(1, Math.floor((Date.now() - new Date(rawEntryTime).getTime()) / 60000))
       : 0;
     ```
5. In `exitFeeCalc`:
   - Pass both `hasActiveTicket: hasValidTicket` and `hasValidTicket`.
6. Forward `hasValidTicket={hasValidTicket}` to `<ExitLanePanel>`:
   ```jsx
   <ExitLanePanel
     detectedPlate={detectedPlate}
     matchedVehicle={matchedVehicle}
     rawLookup={rawLookup}
     scanDetails={scanDetails}
     hasValidTicket={hasValidTicket}
     exitFeeCalc={exitFeeCalc}
     calculatedDurationMinutes={calculatedDurationMinutes}
     isFeeExempt={isFeeExempt}
     setIsFeeExempt={setIsFeeExempt}
     paymentMethod={paymentMethod}
     setPaymentMethod={setPaymentMethod}
     isActionPending={isActionPending}
     onConfirmExit={handleConfirmExit}
   />
   ```

### Step 6: Update `src/components/VehicleManagement/GateCameraControlModal.jsx`
Mirror the changes from Step 5:
1. In `handleMatchPlate`: Query open session from `getParkingSessions` if missing from `lookupVehicleByPlate`.
2. In `handleConfirmEntry`: Pass `imageUrl` to `checkInVehicle`.
3. Change default `calculatedDurationMinutes` fallback from `150` to `0`.
4. In `exitFeeCalc`: Pass `hasActiveTicket: hasValidTicket`.
5. Forward `hasValidTicket={hasValidTicket}` to `<ExitLanePanel>`.

### Step 7: Add Unit Test `VEHICLE-19` to `tests/vehicleManagement.test.mjs`
Append the following test at the end of `tests/vehicleManagement.test.mjs`:
```javascript
test("VEHICLE-19: Walk-in vehicles receive 'Vé lượt vãng lai' badge and do NOT receive false positive 'Vé tháng hiệu lực'", async () => {
  const { mapPlateScanToVehicle, isVehicleTicketActive } = await import(
    "../src/utils/parking/plateScanMapper.js"
  );

  // 1. Walk-in scan (no lookup, casual car)
  const walkInScan = {
    license_plate: "51K-123.45",
    plate_final: "51K-123.45",
    confidence: 88,
    vehicle_lookup: null,
  };
  const walkInVehicle = mapPlateScanToVehicle(walkInScan);
  assert.ok(walkInVehicle);
  assert.equal(walkInVehicle.ticket.type, "Vé lượt");
  assert.equal(
    isVehicleTicketActive(walkInVehicle, false),
    false,
    "Walk-in vehicle without active subscription must NOT have isTicketActive = true"
  );

  // 2. Registered vehicle with expired ticket
  const expiredScan = {
    license_plate: "29A-888.88",
    plate_final: "29A-888.88",
    confidence: 92,
    vehicle_lookup: {
      vehicle: { id: 101, license_plate: "29A-888.88" },
      active_ticket: {
        package_name: "Vé tháng",
        status: "expired",
        is_expired: true,
        is_active: false,
      },
    },
  };
  const expiredVehicle = mapPlateScanToVehicle(expiredScan);
  assert.equal(
    isVehicleTicketActive(expiredVehicle, false),
    false,
    "Vehicle with expired ticket must NOT have isTicketActive = true"
  );

  // 3. Registered vehicle with valid active monthly ticket
  const activeMonthlyScan = {
    license_plate: "30A-999.99",
    plate_final: "30A-999.99",
    confidence: 96,
    vehicle_lookup: {
      vehicle: { id: 102, license_plate: "30A-999.99" },
      active_ticket: {
        package_name: "Vé tháng",
        status: "active",
        is_active: true,
        effective_to: "2026-12-31",
      },
    },
  };
  const activeVehicle = mapPlateScanToVehicle(activeMonthlyScan);
  assert.equal(
    isVehicleTicketActive(activeVehicle, false),
    true,
    "Registered vehicle with active ticket must have isTicketActive = true"
  );

  // 4. Parity with hasValidTicket override prop
  assert.equal(
    isVehicleTicketActive(walkInVehicle, true),
    true,
    "hasValidTicket prop must override when explicitly asserted by lane orchestrator"
  );
});
```

---

## 5. Verification Method

### 5.1 Empirical Ticket Badge & Walk-in Verification
Run via Node CLI:
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
  const active = m.isVehicleTicketActive(walkInVehicle, false);
  console.log('Walk-in badge active status:', active);
  if (active === false) {
    console.log('PASS: Correctly resolved as Ve luot vang lai');
  } else {
    console.error('FAIL: False positive Ve thang hieu luc detected');
    process.exit(1);
  }
});
"
```
**Expected Output**: `PASS: Correctly resolved as Ve luot vang lai`.

### 5.2 Unit Test Suite Execution
Execute from repository root:
```powershell
npm --prefix parking_management_frontend run test:unit
```
**Expected Output**: 83 passed, 0 failed (82 existing + `VEHICLE-19`).

### 5.3 Production Build Verification
Execute from repository root:
```powershell
npm --prefix parking_management_frontend run build
```
**Expected Output**: Exit code 0, 0 build errors.

### 5.4 Backend Code Lock & Git Safety Verification
Execute:
```powershell
git status --short parking_management_backend/
```
**Expected Output**: Empty output (0 files modified in backend).
