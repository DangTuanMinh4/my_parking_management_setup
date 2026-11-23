# Handoff Report: Requirement R1 (Plate Scan & Auto-fill Explorer)

**Working Directory**: `e:\code\parking_management\.agents\teamwork\explorer_survey_r1\`  
**Target Project**: `parking_management_frontend/`  
**Date**: 2026-11-05T19:23:00Z  
**Explorer**: Explorer 1 (Plate Scan & Auto-fill Explorer)  
**Recipient**: Orchestrator (`d867b49c-6937-4ba4-9c23-b96b03e107b6`)

---

## 1. Observation

### 1.1 Component Inventory & Current Structure
- `src/components/VehicleManagement/ScanPlateModal.jsx`: Modal opened from `PageSectionHeader.jsx` in `pages/VehicleManagement.jsx` (lines 635–641). Currently has a 2-column layout:
  - Left column: `<ScanPlateCameraFeed />` (line 490)
  - Right column: `<EntryLanePanel />` (lines 509–526) or `<ExitLanePanel />` (lines 528–541)
  - Top search bar: `<input value={detectedPlate} />` and `<button type="submit">Tra cứu</button>` (lines 440–455).
- `src/components/VehicleManagement/scanPlate/ScanPlateCameraFeed.jsx`: Video element connected to `videoRef`, bounding box overlay, camera device dropdown, and barrier indicator bar.
- `src/components/VehicleManagement/scanPlate/EntryLanePanel.jsx`: Check-in panel displaying vehicle card, ticket status badge, available slot selector, blacklist warning, and check-in button.
- `src/components/VehicleManagement/scanPlate/ExitLanePanel.jsx`: Check-out panel displaying session timestamps (entry, exit, duration), fee calculation, payment mode (Cash/VietQR), and check-out button.
- `src/components/VehicleManagement/GateCameraControlModal.jsx`: Almost identical to `ScanPlateModal.jsx`, mounted in `src/components/layout/AppTopHeader.jsx` (line 365).
- `src/components/PlateScannerModal.jsx`: Standalone camera modal displaying confidence percentage, editable plate text, review status chip, and vehicle details.

### 1.2 Camera Auto-Detection Defect in `ScanPlateModal.jsx`
- In `src/hooks/usePlateAutoDetect.js` (lines 353–367), the hook returns:
  ```javascript
  return {
    scanState: snapshot.scanState,
    cameraError: cameraDeviceError,
    scanError: snapshot.scanState === SCAN_STATES.ERROR ? snapshot.errorMessage : '',
    videoDevices,
    selectedDeviceId,
    changeCamera,
    statusMessage: snapshot.statusMessage,
    detectedData: snapshot.detectedData,
    rawBoundingBox: snapshot.rawBoundingBox,
    sourceDimensions: snapshot.sourceDimensions,
    resetDetection,
    applyAuthoritativeScan,
  };
  ```
- In `src/components/VehicleManagement/ScanPlateModal.jsx` (lines 94–107), `usePlateAutoDetect` is invoked:
  ```javascript
  const {
    cameraError,
    videoDevices,
    selectedDeviceId,
    changeCamera,
    statusMessage,
    rawBoundingBox,
    sourceDimensions,
    resetDetection,
  } = usePlateAutoDetect({
    isOpen,
    videoRef,
    gateId: activeGateId,
  });
  ```
  **Direct Observation**: `detectedData` and `scanState` are **completely omitted** from the destructuring in `ScanPlateModal.jsx` (and likewise in `GateCameraControlModal.jsx` line 91). There is **no effect or callback** listening to camera detection. As a result, the camera stream runs in the background but **never auto-fills `detectedPlate` or triggers vehicle lookup**. The plate is only set if the user manually types into the input box!
- By contrast, in `src/components/PlateScannerModal.jsx` (lines 36, 83–90):
  ```javascript
  const currentDetectedPlate = detectedData?.plate_final || null;
  if (currentDetectedPlate !== prevDetectedPlate) {
    setPrevDetectedPlate(currentDetectedPlate);
    setUserEditedPlate(null);
    ...
  }
  ```
  `PlateScannerModal` properly monitors `detectedData`.

### 1.3 Image Upload Mechanism & Existing Service
- `src/services/plateScanService.js` (lines 48–57):
  ```javascript
  export async function scanPlateImage(imageFile, gateId = 1) {
    const formData = new FormData();
    formData.append("image", imageFile);
    formData.append("gate_id", gateId);

    return apiClient("/api/v1/parking/plate-scans/", {
      method: "POST",
      body: formData,
    });
  }
  ```
  `scanPlateImage` is fully implemented and tested (see `tests/cameraPlateScan.test.mjs` line 6).
- In `src/hooks/usePlateScan.js` (lines 32–57), `scanImage(imageFile, gateId)` is also defined with AbortController and search history tracking.
- In git commit `fce1a3d:src/components/VehicleManagement/ScanPlateModal.jsx` (lines 248–290), `ScanPlateModal` previously contained an image upload handler (`runOcrScan(file)` calling `scanPlateImage(file)`). During the layout overhaul into a 2-column camera view, file input and drag & drop UI were removed from `ScanPlateModal.jsx`.

### 1.4 Vehicle Details Lookup & Exact Property Mapping
When a license plate is recognized, matching occurs through two pathways:
1. **Backend REST API**:
   `lookupVehicleByPlate(licensePlate)` in `src/services/plateScanService.js` (lines 62–66):
   `GET /api/v1/parking/vehicle-lookup/?license_plate=${cleanPlate}`
   Mapped via `mapVehicleLookupToVehicle(lookupResult)` in `src/utils/parking/plateScanMapper.js`.
2. **Client Store Fallback**:
   In `ScanPlateModal.jsx` (lines 154–160):
   ```javascript
   const findInLocalList = useCallback(
     (norm) => {
       const list = Array.isArray(vehicles) && vehicles.length > 0 ? vehicles : mockVehicles;
       return list.find((v) => normalizePlate(v.licensePlate) === norm) || null;
     },
     [vehicles]
   );
   ```
   The `vehicles` array is provided by `useVehicleData()` in `src/pages/VehicleManagement.jsx` (line 59), populated via `fetchVehicles()` + `customerService.getCustomers()` + `getActiveSessions()` in `src/hooks/useVehicleData.js`.

The 5 exact required fields map across Frontend models as follows:
| No. | Required Field | Model Property (`useVehicleData`) | Mapper Property (`plateScanMapper`) | Fallback Value |
|:---:|---|---|---|---|
| 1 | **Tên xe** | `vehicle.model` | `vehicle.model` / `rawVehicle.model_name` | `"Xe vãng lai"` / `"—"` |
| 2 | **Hãng xe** | `vehicle.brand` | `vehicle.brand` | `"—"` |
| 3 | **Tên khách hàng** | `vehicle.customer?.name` | `vehicle.customer.name` / `vehicle.customerName` | `"Khách vãng lai"` |
| 4 | **Số điện thoại** | `vehicle.customer?.phone` | `vehicle.customer.phone` / `vehicle.customerPhone` | `"—"` |
| 5 | **Vị trí đỗ** | `vehicle.parkingSlot?.display` | `vehicle.parkingSlot.display` / `vehicle.slotCode` | `"Chưa có vị trí"` / `"Chưa xếp chỗ"` |

### 1.5 Identified UI Discrepancies Between Flows & Panels
1. **`EntryLanePanel.jsx` (lines 62–95)**:
   - "Chủ xe" is displayed as `matchedVehicle?.customer?.name`.
   - "Số điện thoại" is displayed as `matchedVehicle?.customer?.phone`.
   - "Dòng xe" combines model and brand: `{matchedVehicle?.model || matchedVehicle?.brand || "Ô tô"}`. There is **no distinct "Hãng xe"** box!
   - "Vị trí đỗ" is only displayed conditionally below the grid (lines 108–118) if `matchedVehicle?.parkingSlot?.display` exists. If empty or unassigned, it does not show in the vehicle card.
2. **`ExitLanePanel.jsx` (lines 24–58)**:
   - Does **NOT** display vehicle or customer information at all! It only renders session timestamps and fee breakdown. The gate operator at the exit lane cannot see the vehicle name, brand, owner name, phone, or assigned parking slot.
3. **Camera vs Image Scan Consistency**:
   - Image scan was missing from UI entirely.
   - Camera scan was missing `detectedData` subscription.
   - Neither flow currently populates all 5 canonical fields simultaneously in both Entry and Exit panels.
4. **Missing Prop in `ScanPlateModal.jsx`**:
   `VehicleManagement.jsx` passes `onCheckInSuccess={handleCheckInSuccess}` (line 640), but `ScanPlateModal.jsx` does not accept `onCheckInSuccess` in its prop signature (line 59) and does not call it after `handleConfirmEntry` (lines 312–330).

### 1.6 Verification of Auto-Paste & Search Sync (Requirement R2)
- In `src/pages/VehicleManagement.jsx` (lines 162–179):
  ```javascript
  const handleVehicleMatchedFromScan = (matchedVehicle) => {
    if (!matchedVehicle) return;
    const plateToSearch = typeof matchedVehicle === 'string'
      ? matchedVehicle
      : (matchedVehicle.licensePlate || matchedVehicle.plate || '');
    if (matchedVehicle.id) {
      setSelectedVehicleId(matchedVehicle.id);
    }
    if (plateToSearch) {
      setFilters((prev) => ({ ...prev, search: plateToSearch }));
      setCurrentPage(1);
    }
    setIsScanModalOpen(false);
    const detailSection = document.getElementById('vehicle-detail-section');
    if (detailSection) {
      detailSection.scrollIntoView({ behavior: 'smooth' });
    }
  };
  ```
- In `src/components/VehicleManagement/ScanPlateModal.jsx` (lines 240–245, 555–563):
  The button `"Xem hồ sơ chi tiết phương tiện →"` calls `handleApplySelection()`, which executes `onVehicleMatched(matchedVehicle)` and closes the modal.
- Unit tests `VEHICLE-12`, `VEHICLE-13`, and `VEHICLE-14` in `tests/vehicleManagement.test.mjs` explicitly test and confirm this auto-paste and search sync behavior. Running `npm --prefix parking_management_frontend run test:unit` shows all 78 tests pass.

---

## 2. Logic Chain

1. **Premise 1 (Missing Image Scan UI)**:
   `plateScanService.scanPlateImage` exists and works via API contract, but `ScanPlateModal.jsx` currently only renders `ScanPlateCameraFeed.jsx`. To fulfill R1, an image upload flow (file picker + drag & drop + preview) must be added beside or toggleable with the camera feed.
2. **Premise 2 (Camera Scan Disconnection)**:
   Because `ScanPlateModal.jsx` does not destructure `detectedData` from `usePlateAutoDetect`, camera detections never propagate to `detectedPlate` or `matchedVehicle`. Destructuring `detectedData` and adding an effect to trigger `handleMatchPlate(plate_final)` immediately fixes the camera flow and brings parity with image scan.
3. **Premise 3 (5-Field Vehicle Information Requirement)**:
   Requirement R1 specifies that whenever a recognized plate matches an existing vehicle, the UI must display: Tên xe, Hãng xe, Tên khách hàng, Số điện thoại, Vị trí đỗ.
   - Observation 1.4 confirms that `model`, `brand`, `customer.name`, `customer.phone`, and `parkingSlot.display` are standardized across both `mapPlateScanToVehicle` (OCR) and `mapVehicleLookupToVehicle` (Lookup) in `plateScanMapper.js`, as well as in `vehicles` from `useVehicleData.js`.
   - Observation 1.5 reveals that `EntryLanePanel.jsx` collapses brand and model into "Dòng xe" and hides slot information unless fixed, while `ExitLanePanel.jsx` omits vehicle info entirely.
   - Therefore, creating a unified vehicle card component (or rendering a 5-box grid in both Entry and Exit panels) ensures that both camera and image scan flows display complete, identical vehicle details across both lanes.
4. **Premise 4 (Preservation of Auto-paste/Search R2)**:
   The existing `handleVehicleMatchedFromScan` function in `VehicleManagement.jsx` already updates `filters.search` and selects `selectedVehicleId`. Preserving the `onVehicleMatched(matchedVehicle)` invocation in `ScanPlateModal.jsx` satisfies R2 without regression.

---

## 3. Caveats

1. **Dual Gate Modes**:
   Gate ID differs by lane: `DEFAULT_ENTRY_GATE_ID = 1` for Làn Vào, and `DEFAULT_EXIT_GATE_ID = 3` for Làn Ra. Both `scanPlate` and `scanPlateImage` should pass the active gate ID (`activeGateId`).
2. **File Size and Format Restrictions**:
   Image upload must validate file types (`image/jpeg`, `image/png`, `image/webp`) and limit file size (e.g. < 10MB) before constructing FormData to avoid unhandled browser memory spikes or server 413 Payload Too Large.
3. **Network Failure / Offline Tolerance (Rule 11 of AI Clean Code)**:
   When offline or backend returns an error (422 Unprocessable Entity, 502 Bad Gateway), the image upload flow must cleanly display a localized message (`setErrorMessage(...)`) and still allow manual lookup / fallback to the client store (`findInLocalList`).
4. **No Direct Backend Changes**:
   Per project rules, no modifications can be made in `parking_management_backend/`. All solutions rely strictly on existing endpoints (`/api/v1/parking/plate-scans/`, `/api/v1/parking/vehicle-lookup/`).

---

## 4. Conclusion & Actionable Blueprint

To implement Requirement R1 cleanly, maintain modularity (files < 200 lines), and ensure strict quality compliance, the implementing agent should execute the following surgical changes:

### Step 1: Create `ScanPlateImageUpload.jsx`
- Path: `src/components/VehicleManagement/scanPlate/ScanPlateImageUpload.jsx` (New component, < 180 lines)
- Features:
  - Drag & drop zone with dashed border and hover state.
  - Hidden `<input type="file" accept="image/png,image/jpeg,image/webp" />` triggered on click or drop.
  - Image preview thumbnail once an image is selected with a "Chọn ảnh khác" button.
  - Loading spinner overlay during OCR scanning.
  - Error alert for unsupported file types or server errors.
  - Callback `onImageScanned(scanResult, previewUrl)` invoking `plateScanService.scanPlateImage(file, gateId)`.

### Step 2: Update `ScanPlateModal.jsx`
- Path: `src/components/VehicleManagement/ScanPlateModal.jsx`
- Changes:
  1. Add scan source toggle above the left column:
     - `[📷 Quét Camera trực tiếp]` vs `[🖼️ Tải ảnh từ file]` (state: `scanSourceMode: 'camera' | 'image'`).
  2. If `scanSourceMode === 'camera'`: render `<ScanPlateCameraFeed />`.
  3. If `scanSourceMode === 'image'`: render `<ScanPlateImageUpload />`.
  4. Fix Camera Auto-Detection:
     - Destructure `detectedData` and `scanState` from `usePlateAutoDetect`.
     - In a `useEffect` watching `detectedData?.plate_final`:
       ```javascript
       useEffect(() => {
         const plate = detectedData?.plate_final;
         if (plate && plate !== detectedPlate) {
           setDetectedPlate(plate);
           handleMatchPlate(plate);
           setScanDetails({
             confidence: extractScanConfidence(detectedData),
             plate,
             source: "camera",
           });
         }
       }, [detectedData?.plate_final]);
       ```
  5. Handle Image Upload Result:
     - When `ScanPlateImageUpload` returns `scanResult`:
       ```javascript
       const extractedText =
         scanResult.plate_final ||
         scanResult.best_candidate?.plate_text ||
         scanResult.plate_raw ||
         scanResult.license_plate ||
         "";
       if (extractedText) {
         setDetectedPlate(extractedText);
         setScanDetails({
           confidence: scanResult.best_candidate?.confidence ?? scanResult.confidence ?? null,
           plate: extractedText,
           imageUrl: scanResult.image_url || previewUrl,
           source: "image",
         });
         const mapped = mapPlateScanToVehicle(scanResult);
         if (mapped && mapped.isRecognized) {
           setMatchedVehicle(mapped);
           setRawLookup(scanResult.vehicle_lookup || null);
         } else {
           handleMatchPlate(extractedText);
         }
       }
       ```
  6. Add `onCheckInSuccess` to prop signature and call it inside `handleConfirmEntry` after check-in completes.

### Step 3: Create `VehicleMatchedInfoCard.jsx`
- Path: `src/components/VehicleManagement/scanPlate/VehicleMatchedInfoCard.jsx` (New component, ~100 lines)
- Render the 5 required fields in a responsive 2-column or 3-column grid:
  1. **Tên xe**: `matchedVehicle?.model || matchedVehicle?.model_name || "—"`
  2. **Hãng xe**: `matchedVehicle?.brand || "—"`
  3. **Tên khách hàng**: `matchedVehicle?.customer?.name || matchedVehicle?.customerName || "Khách vãng lai"`
  4. **Số điện thoại**: `matchedVehicle?.customer?.phone || matchedVehicle?.customerPhone || "—"`
  5. **Vị trí đỗ**: `matchedVehicle?.parkingSlot?.display || matchedVehicle?.parkingSlot?.slot || matchedVehicle?.slotCode || "Chưa có vị trí"`
  - Also include the ticket status badge (Vé tháng hiệu lực / Vé lượt vãng lai) and AI confidence pill.

### Step 4: Integrate `VehicleMatchedInfoCard` into `EntryLanePanel.jsx` and `ExitLanePanel.jsx`
- Replace lines 46–95 in `EntryLanePanel.jsx` with `<VehicleMatchedInfoCard matchedVehicle={matchedVehicle} scanDetails={scanDetails} />`.
- Insert `<VehicleMatchedInfoCard matchedVehicle={matchedVehicle} scanDetails={scanDetails} />` at the top of `ExitLanePanel.jsx` (above session timestamps) so exit lane operators also see the complete vehicle details.

### Step 5: Mirror Improvements in `GateCameraControlModal.jsx`
- Ensure `GateCameraControlModal.jsx` also destructures `detectedData` and auto-matches plates so the top header camera modal functions identically.

---

## 5. Verification Method

### 5.1 Automated Unit Tests
Run the unit test suite:
```powershell
npm --prefix parking_management_frontend run test:unit
```
Expected result: All 78+ unit tests pass, specifically `CAMERA-01` through `CAMERA-06` and `VEHICLE-12`, `VEHICLE-13`, `VEHICLE-14`.

### 5.2 Add New Unit Tests for Image Scan & 5-Field Alignment
Add unit tests in `parking_management_frontend/tests/vehicleManagement.test.mjs` verifying:
1. `VEHICLE-16: Image scan file upload extracts plate and maps the 5 canonical fields (Tên xe, Hãng xe, Khách hàng, SĐT, Vị trí đỗ)`.
2. `VEHICLE-17: ExitLanePanel renders vehicle details matching EntryLanePanel`.
3. `VEHICLE-18: Camera auto-detect effect triggers handleMatchPlate without user manual typing`.

### 5.3 Production Build Verification
Execute Vite production build:
```powershell
npm --prefix parking_management_frontend run build
```
Expected result: Exits with code 0 (`✓ built in ...s`).

### 5.4 Invalidation Conditions
- Any edit made inside `parking_management_backend/`.
- Regression in `VEHICLE-12`, `VEHICLE-13`, `VEHICLE-14` (auto-paste to search filter).
- Any file in `src/components/VehicleManagement/` exceeding 250 lines without modularization.
- Hardcoded or mock AI confidence values (violating Rule 2 of AI Clean Code).
