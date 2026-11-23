# Báo Cáo Điều Tra Yêu Cầu R2: Tự Động Điền/Paste Biển Số Xe & Ranh Giới Tính Năng "Tìm Xe"

**Agent**: Explorer 2 (Plate Paste & Boundary Explorer)  
**Thời gian hoàn thành**: 2026-11-05T19:22:30Z  
**Phạm vi**: `parking_management_frontend/` (Strict Read-Only, Frontend Lock, Strict Git Safety)  
**Tập tin báo cáo**: `e:\code\parking_management\.agents\teamwork\explorer_survey_r2\handoff.md`

---

## 1. Observation (Các quan sát thực tế)

### 1.1. Luồng Callback & Cầu Nối Giữa `ScanPlateModal` và `VehicleManagement`
- **File**: `parking_management_frontend/src/pages/VehicleManagement.jsx`
  - **Dòng 70**: Khởi tạo state hiển thị modal quét biển số:
    ```javascript
    const [isScanModalOpen, setIsScanModalOpen] = useState(false);
    ```
  - **Dòng 544**: Kích hoạt mở modal từ `PageSectionHeader`:
    ```javascript
    onOpenScanModal={() => setIsScanModalOpen(true)}
    ```
  - **Dòng 635–641**: Nhúng và truyền props cho `ScanPlateModal`:
    ```javascript
    <ScanPlateModal
      isOpen={isScanModalOpen}
      onClose={() => setIsScanModalOpen(false)}
      vehicles={vehicles}
      onVehicleMatched={handleVehicleMatchedFromScan}
      onCheckInSuccess={handleCheckInSuccess}
    />
    ```
  - **Dòng 162–179**: Hàm nhận kết quả biển số và paste vào bộ lọc tìm kiếm (`handleVehicleMatchedFromScan`):
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

### 1.2. Ô Tìm Kiếm Tại Giao Diện `VehicleFilters.jsx`
- **File**: `parking_management_frontend/src/components/VehicleManagement/VehicleFilters.jsx`
  - **Dòng 28–55**: Ô nhập liệu tìm kiếm nhận prop `value={filters.search}` và sự kiện `onChange`:
    ```javascript
    <FormInput
      label="Tìm kiếm phương tiện"
      placeholder="Tìm biển số, tên hoặc SĐT khách hàng..."
      value={filters.search}
      onChange={(e) => onFilterChange("search", e.target.value)}
      onKeyDown={(e) => {
        if (e.key === "Enter" && onSearch) {
          onSearch();
        }
      }}
      leftIcon={...}
    />
    ```
- **File**: `parking_management_frontend/src/pages/VehicleManagement.jsx`
  - **Dòng 558–566**: Kết nối `filters` và `setFilters` với `VehicleFilters`:
    ```javascript
    <VehicleFilters
      filters={filters}
      onFilterChange={(key, val) => {
        setFilters((prev) => ({ ...prev, [key]: val }));
        setCurrentPage(1);
      }}
      onSearch={() => setCurrentPage(1)}
      onReset={handleResetFilters}
    />
    ```
  - **Dòng 104–143**: `filteredVehicles` lọc danh sách xe theo `filters.search` với cả so khớp chuỗi thô (`matchesRaw`) và chuẩn hóa dấu tiếng Việt (`matchesNormalized` qua helper `normalizeSearchText`).

### 1.3. Luồng Xử Lý Nhận Diện & Áp Dụng Biển Số Trong `ScanPlateModal.jsx`
- **File**: `parking_management_frontend/src/components/VehicleManagement/ScanPlateModal.jsx`
  - **Dòng 240–245**: Nút xác nhận áp dụng biển số gọi callback `onVehicleMatched`:
    ```javascript
    const handleApplySelection = () => {
      if (matchedVehicle && onVehicleMatched) {
        onVehicleMatched(matchedVehicle);
      }
      onClose();
    };
    ```
  - **Dòng 555–563**: Nút bấm tại chân Modal kích hoạt `handleApplySelection`:
    ```javascript
    {matchedVehicle && (
      <button
        type="button"
        onClick={handleApplySelection}
        className="px-4 py-2 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-100 border border-slate-300 rounded-xl shadow-2xs transition"
      >
        Xem hồ sơ chi tiết phương tiện →
      </button>
    )}
    ```
  - **Dòng 162–220**: Hàm `handleMatchPlate(plateInput)`:
    - Gọi API backend qua `lookupVehicleByPlate(rawInput)`
    - Chuyển đổi dữ liệu qua `mapVehicleLookupToVehicle(lookupResult)`
    - Fallback 1: Tìm trong danh sách `vehicles` local (`findInLocalList(norm)`)
    - Fallback 2: Tạo đối tượng xe vãng lai (`WALK_IN_${Date.now()}`)
    - Cập nhật state `setMatchedVehicle(vehicle)`
  - **Dòng 94–107**: Gọi hook `usePlateAutoDetect`:
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
    ⚠️ **Quan sát khiếm khuyết (Gap/Bug phát hiện)**: `usePlateAutoDetect` trả về `detectedData` (chứa `plate_final`, `vehicle_lookup`, v.v.), nhưng `ScanPlateModal.jsx` **không** destructure `detectedData` và **không** có `useEffect` lắng nghe kết quả camera nhận diện tự động. Do đó, luồng live camera nhận diện được biển số nhưng không tự động đưa vào `detectedPlate` hay gọi `handleMatchPlate`. Người dùng hiện tại chỉ có thể nhập tay biển số vào ô input ở dòng 444 rồi bấm nút "Tra cứu" (dòng 451) để kích hoạt.

### 1.4. Vị Trí Tính Năng "Tìm Xe" (Vehicle Locator) Trong Toàn Bộ Dự Án
- **File**: `parking_management_frontend/src/pages/ParkingLotManagement.jsx` (Sơ đồ bãi đậu xe, Route `/parking-lot`)
  - **Dòng 233–258**: Hàm `matchesFilter` lọc và tìm kiếm vị trí ô đỗ theo biển số xe hoặc mã ô đỗ:
    ```javascript
    if (searchQuery.trim()) {
      const q = searchQuery.trim().toLowerCase();
      const matchLabel = String(slot.label || slot.code || slot.id || "").toLowerCase().includes(q);
      const matchPlate = String(slot.plate || slot.licensePlate || "").toLowerCase().includes(q);
      if (!matchLabel && !matchPlate) return false;
    }
    ```
- **File**: `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotFilters.jsx`
  - **Dòng 75–81**: Ô tìm kiếm trên sơ đồ bãi đỗ:
    ```javascript
    <FormInput
      label="Tìm kiếm"
      placeholder="Mã ô hoặc biển số..."
      value={searchQuery}
      onChange={(e) => setSearchQuery(e.target.value)}
      leftIcon={<Search className="w-3.5 h-3.5 text-slate-400" />}
    />
    ```
- **Tài liệu tham chiếu**:
  - `docs/02-srs.md` Mục 3.5 "Phân hệ bản đồ vị trí đỗ xe": Hiển thị sơ đồ vị trí đỗ xe theo tầng, tìm kiếm vị trí ô đỗ, hiển thị thông tin xe đang đỗ tại ô.
  - `docs/05-testing.md` Kịch bản `ST-CORE-09`: "Báo mất vé / Tìm kiếm xe theo biển số" trong phân hệ bãi xe.

### 1.5. Kết Quả Kiểm Thử Độc Lập Hiện Có
- Chạy lệnh: `cd parking_management_frontend; node --test tests/vehicleManagement.test.mjs`
- Kết quả: **15/15 test passed**, trong đó:
  - `VEHICLE-12`: "Scan plate synchronization updates search filter state and triggers matching filter" (Xác nhận logic đồng bộ biển số quét vào search filter của `VehicleManagement`).
  - `VEHICLE-13`: "Scan sync search filter accurately narrows vehicle list with Vietnamese normalization" (Xác nhận logic lọc tiếng Việt có/không dấu).
  - `VEHICLE-14`: "Camera auto-paste synchronization fills search input and triggers vehicle matching" (Xác nhận kỳ vọng auto-paste từ camera nhận diện sang search).

---

## 2. Logic Chain (Chuỗi lập luận và phân tích)

1. **Từ Quan sát 1.1 và 1.2**:
   - Khi modal quét biển số hoàn tất và người dùng xác nhận xem chi tiết xe, `ScanPlateModal` gọi `onVehicleMatched(matchedVehicle)`.
   - Hàm `handleVehicleMatchedFromScan` tại `VehicleManagement.jsx` trích xuất `plateToSearch` (từ `matchedVehicle.licensePlate` hoặc dạng chuỗi thuần).
   - Biến trạng thái `filters.search` lập tức được gán bằng `plateToSearch` (`setFilters((prev) => ({ ...prev, search: plateToSearch }))`).
   - Component `VehicleFilters.jsx` nhận trực tiếp `filters.search` qua props và hiển thị chuỗi biển số vào ô `<FormInput label="Tìm kiếm phương tiện" ... />`.
   - Đồng thời, `filteredVehicles` áp dụng bộ lọc biển số này để thu hẹp bảng dữ liệu, và trang được cuộn mượt xuống card chi tiết xe (`vehicle-detail-section`).
   - **Kết luận bước 1**: Tính năng auto-fill/paste biển số vào ô tìm kiếm danh bạ xe **đã tồn tại trong code**, có hợp đồng rõ ràng và hoạt động chính xác theo thiết kế.

2. **Từ Quan sát 1.3**:
   - Trong `ScanPlateModal.jsx`, do `usePlateAutoDetect` không được destructure trường `detectedData`, luồng nhận diện camera thời gian thực không tự động điền biển số vào `detectedPlate`.
   - Thay vào đó, nó đang phụ thuộc vào việc người dùng nhập tay vào ô tìm kiếm modal và bấm "Tra cứu".
   - Khi thêm tính năng quét biển số từ file ảnh (Requirement R1), nếu Worker không chủ động cập nhật `detectedPlate` và gọi `handleMatchPlate(plate)`, người dùng sẽ không kích hoạt được nút "Xem hồ sơ chi tiết phương tiện →" để auto-paste biển số ra màn hình chính.
   - **Kết luận bước 2**: Worker Milestone 1 & 2 cần bổ sung việc lắng nghe `detectedData?.plate_final` (từ camera) và kết quả OCR từ file ảnh để tự động điền `detectedPlate` và kích hoạt `handleMatchPlate`.

3. **Từ Quan sát 1.4**:
   - Tính năng "Tìm xe" (tìm vị trí ô đỗ của phương tiện trong bãi đỗ xe theo tầng, khu vực và mã ô đỗ) nằm hoàn toàn tại trang `ParkingLotManagement.jsx` (route `/parking-lot`) cùng các components tại `src/components/ParkingLotManagement/`.
   - Tính năng Quản lý xe và tìm kiếm danh bạ phương tiện (Vehicle Management) nằm tại `src/pages/VehicleManagement.jsx` (route `/vehicles`).
   - Hai tính năng này hoàn toàn độc lập về mặt router, state và components, chỉ chia sẻ các model dùng chung qua `services/`.
   - **Kết luận bước 3**: Việc định ranh giới là tuyệt đối khả thi và đơn giản bằng cách thiết lập danh sách file cấm sửa đổi (DO-NOT-TOUCH).

---

## 3. Caveats (Các điểm cần lưu ý & Giả định)

1. **Giả định về nút hành động**:
   - Hiện tại, việc paste biển số ra ô tìm kiếm trang cha diễn ra khi người dùng bấm nút *"Xem hồ sơ chi tiết phương tiện →"* (`handleApplySelection`). Nếu yêu cầu muốn paste ngay lập tức khi camera/ảnh vừa nhận diện thành công mà không cần bấm nút, cần bổ sung một tùy chọn callback trực tiếp hoặc auto-apply. Tuy nhiên, luồng có nút bấm giúp người dùng có cơ hội xem trước thông tin soát vé tại trạm (Làn Vào/Ra) trước khi điều hướng ra danh sách.
2. **Trường hợp xe vãng lai chưa đăng ký**:
   - Khi quét một xe chưa từng có trong danh bạ bãi xe, hệ thống tạo đối tượng `WALK_IN_${Date.now()}`. Khi paste ra ngoài, `filters.search` vẫn nhận đúng biển số, nhưng bảng `VehicleTable` sẽ hiển thị rỗng (*"Không tìm thấy phương tiện nào phù hợp với bộ lọc"*). Đây là hành vi đúng đắn vì danh sách này là danh bạ xe đăng ký.
3. **Các file Backend**:
   - Toàn bộ backend tại `parking_management_backend/` tuân thủ nghiêm ngặt chế độ khóa (Strict Backend Lock), không kiểm tra và không can thiệp.

---

## 4. Conclusion (Kết luận & Phân định ranh giới)

### 4.1. Bản Đồ Hợp Đồng Tính Năng Auto-Fill / Paste Biển Số (R2)

| Khâu | Component / File | Logic thực thi | Trạng thái hiện tại |
|---|---|---|---|
| **1. Kích hoạt quét** | `PageSectionHeader.jsx:27` | Bấm nút *"Scan biển số"* -> `setIsScanModalOpen(true)` | Hoạt động tốt |
| **2. Nhận diện biển số** | `ScanPlateModal.jsx:162` | `handleMatchPlate(plate)` tra cứu API / local list | Hoạt động khi nhập tay; thiếu hook auto-listen camera `detectedData` |
| **3. Cầu nối paste** | `ScanPlateModal.jsx:240` | Bấm *"Xem hồ sơ chi tiết phương tiện →"* gọi `onVehicleMatched(matchedVehicle)` | Hoạt động tốt |
| **4. Tiếp nhận & Điền biển số** | `VehicleManagement.jsx:162` | `handleVehicleMatchedFromScan` cập nhật `filters.search = plateToSearch` | Hoạt động tốt |
| **5. Hiển thị UI** | `VehicleFilters.jsx:28` | `<FormInput value={filters.search} ... />` hiển thị biển số ngay lập tức | Hoạt động tốt |
| **6. Lọc & Xem chi tiết** | `VehicleManagement.jsx:104, 175` | Lọc bảng theo biển số, cuộn mượt xuống card chi tiết | Hoạt động tốt |

### 4.2. Danh Sách Ranh Giới Nghiêm Ngặt "TÌM XE" (DO-NOT-TOUCH BOUNDARIES)

Nghiêm cấm tuyệt đối các Agent/Worker thuộc nhóm R1, R2, R3 chỉnh sửa, can thiệp hoặc di dời code trong các file sau đây:

```
🚫 DO-NOT-TOUCH (Phạm vi của thành viên khác phụ trách "Tìm xe"):
├── src/pages/ParkingLotManagement.jsx
├── src/components/ParkingLotManagement/
│   ├── ParkingLotFilters.jsx
│   ├── ParkingSlotMatrix.jsx
│   ├── ParkingSlotListView.jsx
│   ├── SlotDetailPanel.jsx
│   ├── ParkingLotStatsCards.jsx
│   ├── ParkingLotStructureAndActivity.jsx
│   ├── AddSlotModal.jsx
│   ├── EditSlotModal.jsx
│   ├── StructureModal.jsx
│   └── OverstayAlertBanner.jsx
├── src/services/parkingLotService.js
├── src/constants/parkingLotConstants.js
├── src/hooks/useParkingLot.js
└── tests/parkingLot*.test.mjs
```

### 4.3. Danh Sách Tệp Tin Cho Phép Thực Hiện R1 & R2 (IN-SCOPE FILES)

```
✅ IN-SCOPE (Thuộc phạm vi R1 & R2):
├── src/pages/VehicleManagement.jsx
├── src/components/VehicleManagement/
│   ├── ScanPlateModal.jsx
│   ├── VehicleFilters.jsx
│   ├── PageSectionHeader.jsx
│   ├── scanPlate/
│   │   ├── ScanPlateCameraFeed.jsx
│   │   ├── EntryLanePanel.jsx
│   │   └── ExitLanePanel.jsx
│   └── icons/vehicleIcons.jsx
├── src/services/plateScanService.js
├── src/utils/parking/plateScanMapper.js
└── tests/vehicleManagement.test.mjs
```

### 4.4. Đề Xuất Hành Động Dành Cho Worker (Milestone 1 & 2)

1. **Bảo toàn hàm `handleVehicleMatchedFromScan`**:
   - Giữ nguyên chữ ký hàm nhận cả object `{ licensePlate: ... }` lẫn string thô.
   - Không xóa hoặc thay đổi tên prop `onVehicleMatched` trong `ScanPlateModal`.
2. **Khắc phục điểm nghẽn auto-detect trong `ScanPlateModal.jsx`**:
   - Thêm `detectedData` vào danh sách destructure từ `usePlateAutoDetect`:
     ```javascript
     const {
       detectedData,
       ...
     } = usePlateAutoDetect({ isOpen, videoRef, gateId: activeGateId });
     ```
   - Thêm hook `useEffect` theo dõi `detectedData?.plate_final`: khi camera nhận diện được biển số mới, tự động `setDetectedPlate(detectedData.plate_final)` và gọi `handleMatchPlate(detectedData.plate_final)`.
3. **Tích hợp quét ảnh (Requirement R1)**:
   - Khi chọn file ảnh và OCR trả về biển số, gán vào `detectedPlate` và kích hoạt `handleMatchPlate(scannedPlate)`.
   - Đảm bảo nút *"Xem hồ sơ chi tiết phương tiện →"* luôn khả dụng sau khi quét ảnh thành công để người dùng có thể paste sang ô tìm kiếm của `VehicleManagement`.

---

## 5. Verification Method (Phương pháp kiểm chứng độc lập)

### 5.1. Kiểm Chứng Bằng Test Runner Của Dự Án
Chạy bộ unit test chuyên biệt cho quản lý xe và đồng bộ quét biển số:
```powershell
cd parking_management_frontend
node --test tests/vehicleManagement.test.mjs
```
- **Kỳ vọng**: 15/15 tests PASS (đặc biệt các test `VEHICLE-12`, `VEHICLE-13`, `VEHICLE-14`).

### 5.2. Kiểm Tra Kiểm Soát Ranh Giới (Diff Check)
Sau khi hoàn thành code, chạy lệnh kiểm tra diff an toàn để đảm bảo không chạm vào bất kỳ file nào thuộc danh sách `DO-NOT-TOUCH`:
```powershell
cd parking_management_frontend
git status --porcelain
```
- **Điều kiện phủ định (Invalidation Condition)**: Nếu xuất hiện bất kỳ file nào trong danh mục `src/pages/ParkingLotManagement.jsx` hoặc `src/components/ParkingLotManagement/*`, việc xác thực bị coi là **THẤT BẠI** do vi phạm ranh giới phân công.
