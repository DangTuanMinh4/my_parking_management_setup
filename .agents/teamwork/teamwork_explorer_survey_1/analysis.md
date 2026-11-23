# Báo Cáo Phân Tích Kỹ Thuật: Hợp Đồng API Backend & Tích Hợp Frontend Cho Quản Lý Sơ Đồ Bãi Xe (Parking Lot & Slots)

- **Người thực hiện**: `teamwork_explorer_survey_1`
- **Mục tiêu**: Khảo sát toàn diện hợp đồng API Backend, hiện trạng Frontend (`parking_management_frontend`), đối chiếu khoảng trống (gap analysis) và thiết kế kiến trúc tích hợp nghiêm ngặt (Strict API Integration, No-Mock Fallback).
- **Ràng buộc tuân thủ**: STRICT BACKEND CODE LOCK (không chỉnh sửa `parking_management_backend/`), STRICT ENV PRIVACY LOCK, Read-only exploration.

---

## 1. Tóm Tắt Phát Hiện Cốt Lõi (Executive Summary)

1. **Backend Hiện Tại Chưa Mở Endpoint Quản Lý Sơ Đồ Vị Trí Bãi Đỗ Xe (Parking Map CRUD)**:
   - Toàn bộ tài liệu chính thức của Backend (`docs/guides/frontend-api/10-troubleshooting-and-cloudinary.md` §14.2 dòng 31, `docs/results-endpoint.md` dòng 73, `docs/uiux-enpoints-ananlysis.md` dòng 64) và router Django (`apps/parking/urls.py`) xác nhận: **Không có endpoint standalone nào cho Parking Map / Parking Slots** (`/api/v1/parking/slots/`, `/api/v1/parking-lots/`, v.v.).
   - Mặc dù cơ sở dữ liệu PostgreSQL 18.6 (`db/01-schema.sql` dòng 757–960) và Django ORM (`apps/parking/models.py`) đã định nghĩa hoàn chỉnh mô hình 4 cấp (`parking_lot` -> `parking_floor` -> `parking_zone` -> `parking_slot`) cùng bảng `slot_reservation`, tầng API REST của Django chưa đăng ký viewset hay route cho nhóm này.
   - Khi Frontend gọi bất kỳ route nào như `GET /api/v1/parking/slots/`, Backend sẽ trả về `HTTP 404 Not Found` qua custom handler `apps.core.exceptions.custom_json_404`.

2. **Dữ Liệu Vận Hành Liên Quan Đến Ô Đỗ Đang Khả Dụng Trên Backend**:
   - Backend hiện có 8 API vận hành trạm kiểm soát xe ra/vào (`/api/v1/parking/*`), trong đó có các API trả về dữ liệu liên quan đến ô đỗ thực tế:
     - `GET /api/v1/parking/sessions/?status=open`: Trả về danh sách các phiên đỗ đang hoạt động, có kèm trường `slot_code` (mã ô đang có xe đỗ thực tế như `"A-06"`), `license_plate`, `entry_time`, v.v.
     - `GET /api/v1/parking/vehicle-lookup/?license_plate=...`: Trả về thông tin vị trí `parking_position` (`slot_id`, `slot_code`, `zone_code`, `floor_code`, `display_text`).
     - `GET /api/v1/parking/vehicle-search/?q=...`: Trả về `parking_position` của phương tiện.
     - `GET /api/v1/vehicles/`: Trả về danh sách xe kèm trường `current_slot` (chuỗi dạng `"Tầng B1 - Zone A - A-06"`).

3. **Hiện Trạng Frontend (`parking_management_frontend`)**:
   - Trang `src/pages/ParkingLotManagement.jsx` hiện đang **hardcode 100% bằng mock data nội bộ**:
     - Import trực tiếp từ `src/mocks/parkingLotData.js` (`fullParkingLotData`).
     - Chỉ đọc cứng `fullParkingLotData[0]?.zones[0]` (Khu A tầng B1); đổi bộ lọc tầng/khu vực không làm thay đổi ma trận ô đỗ.
     - Các nút đổi trạng thái trong `SlotDetailPanel.jsx` chỉ sửa state cục bộ `selectedSlot`, không tác động lên danh sách ô hay gọi bất kỳ API nào.
     - Không có service (`parkingLotService.js`) và không có custom hook (`useParkingLot.js`).

4. **Kế Hoạch Khắc Phục Nghiêm Ngặt Theo Yêu Cầu R2 (Strict API Mode, No Mock Fallback)**:
   - Xây dựng `parkingLotService.js` sử dụng `apiClient.js` chuẩn hóa.
   - Xây dựng custom hook `useParkingLot.js` quản lý vòng đời dữ liệu, gọi API thực tế.
   - Khi API Backend trả về HTTP 404 hoặc lỗi mạng, **tuyệt đối không fallback về mock data**; kích hoạt state `errorMessage` và hiển thị Banner cảnh báo lỗi kết nối rõ ràng trên UI, đồng thời cung cấp nút "Thử lại".

---

## 2. Chi Tiết Khảo Sát Backend API Contracts

### 2.1. Danh mục các Endpoint liên quan đến Bãi đỗ xe & Ô đỗ

| HTTP Method | URL Endpoint | Trạng thái triển khai Backend | Vai trò & Khả năng khai thác | Payload / Tham số | Phản hồi (Response Schema) |
|---|---|---|---|---|---|
| `GET` | `/api/v1/parking/slots/` | ❌ **Chưa triển khai** (Trả về 404) | Lấy danh sách ô đỗ theo tầng/khu vực (Theo SRS 4.8.1) | Query: `floor`, `zone`, `status`, `slot_kind`, `page`, `page_size` | Chuẩn DRF pagination: `{ count, results: [{ id, code, slot_kind, status, map_row, map_col, width, length, height, notes }] }` |
| `POST` | `/api/v1/parking/slots/` | ❌ **Chưa triển khai** (Trả về 404) | Thêm mới vị trí đỗ xe (Theo SRS 4.8.2) | Body: `{ zone_id, code, slot_kind, width, length, height, notes }` | `201 Created`: `{ id, code, ... }` |
| `PATCH` | `/api/v1/parking/slots/{id}/` | ❌ **Chưa triển khai** (Trả về 404) | Cập nhật thông tin/trạng thái ô đỗ (Theo SRS 4.8.3) | Body: `{ row_version, status, slot_kind, notes, ... }` | `200 OK`: `{ id, code, status, row_version, ... }` |
| `DELETE` | `/api/v1/parking/slots/{id}/` | ❌ **Chưa triển khai** (Trả về 404) | Xóa mềm ô đỗ (Theo SRS 4.8.5, DEL-05) | Headers: `X-CSRFToken` | `200 OK`: `{ "message": "Xóa thành công" }` |
| `GET` | `/api/v1/parking/sessions/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Lấy danh sách phiên đỗ (có thể lọc `?status=open` để biết ô nào đang đỗ xe) | Query: `status=open`, `page`, `page_size=100` | `{ count, results: [{ id, session_code, license_plate, slot_code, entry_time, entry_gate_name, vehicle_model, customer_name, customer_phone }] }` |
| `GET` | `/api/v1/parking/vehicle-lookup/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Tra cứu vị trí ô đỗ cụ thể của 1 biển số xe | Query: `license_plate` (bắt buộc) | `{ vehicle, customer, parking_position: { slot_id, slot_code, zone_code, floor_code, floor_name, display_text }, active_ticket, open_session }` |
| `GET` | `/api/v1/parking/vehicle-search/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Tìm kiếm xe và vị trí đỗ đa tiêu chí | Query: `q` (tối thiểu 2 ký tự), `customer_name`, `phone`, `license_plate` | `{ count, results: [{ vehicle, customer, parking_position, open_session, currently_parked }] }` |
| `GET` | `/api/v1/parking/gates/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Lấy danh sách barrier gates theo bãi | Query: `direction=IN/OUT`, `is_active=true` | `[{ id, lot_id, code, name, direction, camera_status, is_auto_scan, is_active }]` |
| `POST` | `/api/v1/parking/sessions/check-in/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Check-in xe vào bãi và gán vào 1 ô đỗ (`slot_id`) | Body: `{ license_plate, entry_gate_id, slot_id, recognition_source, ai_confidence }` | `201 Created`: `{ session: { id, session_code, slot_id, slot_display, license_plate, entry_time }, vehicle_lookup }` |
| `POST` | `/api/v1/parking/sessions/check-out/` | ✅ **Đã hoạt động** (`IsEmployeeOrManager`) | Check-out giải phóng ô đỗ và thu phí | Body: `{ session_code / license_plate, exit_gate_id, payment_method }` | `200 OK`: `{ session: { ..., exit_time, duration_text, fee_amount }, payment }` |

### 2.2. Dữ liệu Cơ sở dữ liệu Thực tế (PostgreSQL 18.6 Schema & Seed)

Theo `parking_management_backend/db/01-schema.sql` và `db/02-seed.sql`:
- **Bãi xe**: Code `'SMART_MOBILITY'`, Tên: `'Bãi xe Smart Mobility'`.
- **Tầng (Floors)**: 3 tầng:
  - `B1` — Tầng B1 (Thứ tự 1)
  - `B2` — Tầng B2 (Thứ tự 2)
  - `F1` — Tầng F1 ngoài trời (Thứ tự 3)
- **Khu vực (Zones)**: Mỗi tầng có 3 khu:
  - `A` — Khu A (Ô tô tiêu chuẩn: A-01 .. A-20)
  - `B` — Khu B (Ô tô ưu tiên & tiêu chuẩn: B-01 .. B-15)
  - `C` — Khu C (Trạm sạc xe điện EV & tiêu chuẩn: C-01 .. C-15)
- **Tổng số ô đỗ**: 150 ô (50 ô mỗi tầng: 20 ô khu A, 15 ô khu B, 15 ô khu C).
  - Tầng B1/A-08 đang được seed trạng thái `MAINTENANCE` ("Đang bảo trì cảm biến siêu âm tại ô A-08").
  - Tầng B2/C-08 đang được seed trạng thái `MAINTENANCE`.
- **Enums hợp lệ của Slot**:
  - `slot_kind`: `'STANDARD'`, `'PRIORITY'`, `'EV_CHARGING'` (và `'VIP'`, `'ACCESSIBLE'` theo models).
  - `status`: `'AVAILABLE'`, `'OCCUPIED'`, `'RESERVED'`, `'CHARGING'`, `'MAINTENANCE'`.

---

## 3. Khảo Sát Hiện Trạng Frontend (`parking_management_frontend`)

### 3.1. Các Tệp Liên Quan Đến Quản Lý Bãi Xe
1. **Trang chính**: `src/pages/ParkingLotManagement.jsx` (186 dòng).
2. **Sub-components**: `src/components/ParkingLotManagement/`:
   - `ParkingLotFilters.jsx` (130 dòng): Bộ lọc bãi, tầng, khu, từ khóa, trạng thái, loại xe.
   - `ParkingLotStatsCards.jsx` (62 dòng): 4 thẻ KPI thống kê (Tổng ô, Ô trống, Đang sử dụng, Đặt trước/Bảo trì).
   - `ParkingSlotMatrix.jsx` (186 dòng): Hiển thị ma trận 2 dãy Dãy A (A1-A08) và Dãy B (B1-B08).
   - `SlotDetailPanel.jsx` (190 dòng): Panel chi tiết ô đang chọn và 4 nút đổi trạng thái nhanh.
   - `ParkingLotStructureAndActivity.jsx` (91 dòng): Danh mục cấu trúc tầng/khu và nhật ký hoạt động.
3. **Mocks & Constants**:
   - `src/mocks/parkingLotData.js`: Chứa `fullParkingLotData` (chỉ có 24 ô của Tầng B1 Khu A).
   - `src/constants/parkingLotConstants.js`: Khai báo danh sách options cho select (`PARKING_FLOOR_OPTIONS`, `PARKING_ZONE_OPTIONS`, v.v.).

### 3.2. Điểm Yếu và Vấn Đề Hiện Tại
1. **Không có kết nối mạng**: Không có bất kỳ lệnh gọi API nào (`fetch` hay `axios`).
2. **Bộ lọc bị vô hiệu hóa logic**: Khi người dùng chọn Tầng `B2` hoặc Khu `B`, giao diện vẫn chỉ hiển thị `fullParkingLotData[0]?.zones[0]` (Tầng B1 - Khu A).
3. **Thao tác trạng thái chỉ là "ảo"**: Khi bấm nút "Đặt làm ô trống", "Đánh dấu có xe đỗ" trong `SlotDetailPanel`, component chỉ cập nhật object `selectedSlot` hiển thị ở cột bên phải, các ô trên ma trận `ParkingSlotMatrix` không hề thay đổi trạng thái.
4. **Vi phạm ESLint / React 19**:
   - Cả 5 component trong `src/components/ParkingLotManagement/` đều có lỗi lint `no-unused-vars` do `import React from "react"`.
   - `ParkingSlotMatrix.jsx` export đồng thời hàm `renderSlotCard` cùng component, gây lỗi `react-refresh/only-export-components`.

---

## 4. Thiết Kế Kiến Trúc Tích Hợp API Thực Tế (Strict API Integration)

Để đáp ứng trọn vẹn yêu cầu R2 từ đề bài:
> *"Tích hợp kết nối API backend thực tế (các endpoint parking-lots/slots) vào hooks và services của Frontend; chỉ gọi API thực tế và hiển thị thông báo lỗi nếu API không phản hồi (không sử dụng mock fallback). Tuân thủ nghiêm ngặt guardrail STRICT BACKEND CODE LOCK: tuyệt đối không chỉnh sửa mã nguồn trong thư mục parking_management_backend/."*

### 4.1. Kiến Trúc Dịch Vụ: `parkingLotService.js`
Tạo mới file `parking_management_frontend/src/services/parkingLotService.js` với các API contract chuẩn hóa:

```javascript
import { apiClient } from "./apiClient.js";

export const parkingLotService = {
  // 1. Lấy danh sách ô đỗ từ backend (Strict API call)
  async getSlots(params = {}) {
    const searchParams = new URLSearchParams();
    if (params.floor) searchParams.append("floor", params.floor);
    if (params.zone) searchParams.append("zone", params.zone);
    if (params.status) searchParams.append("status", params.status);
    if (params.slot_kind) searchParams.append("slot_kind", params.slot_kind);
    if (params.search) searchParams.append("search", params.search);

    const query = searchParams.toString();
    const endpoint = `/api/v1/parking/slots/${query ? `?${query}` : ""}`;
    return await apiClient(endpoint);
  },

  // 2. Lấy danh sách phiên đỗ đang hoạt động để đối soát ô có xe thực tế (Endpoint thực tế có sẵn trên BE)
  async getOpenSessions() {
    return await apiClient("/api/v1/parking/sessions/?status=open&page_size=100");
  },

  // 3. Cập nhật trạng thái ô đỗ
  async updateSlot(slotId, payload) {
    return await apiClient(`/api/v1/parking/slots/${slotId}/`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  },

  // 4. Thêm mới ô đỗ
  async createSlot(payload) {
    return await apiClient("/api/v1/parking/slots/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  },

  // 5. Xóa ô đỗ
  async deleteSlot(slotId) {
    return await apiClient(`/api/v1/parking/slots/${slotId}/`, {
      method: "DELETE",
    });
  },
};
```

### 4.2. Kiến Trúc Custom Hook: `useParkingLot.js`
Tạo mới file `parking_management_frontend/src/hooks/useParkingLot.js`:
- Quản lý state:
  - `slots`: Mảng ô đỗ tải từ API (mặc định là `[]`).
  - `isLoading`: Boolean.
  - `error`: Lưu trữ thông tin lỗi chi tiết (`{ message, status, code, isUnbuilt }`).
  - `selectedFloor`, `selectedZone`, `filters`.
  - `selectedSlot`: Ô đỗ đang chọn xem chi tiết.
- **Xử lý lỗi nghiêm ngặt (Strict Error Handling, NO Mock Fallback)**:
  - Khi `apiClient` quăng lỗi (HTTP 404 do Backend chưa mở route, hoặc `API_UNAVAILABLE` do mất kết nối mạng):
    - Hook bắt lỗi trong khối `catch`.
    - Phân loại lỗi:
      - Nếu `status === 404`: Gán thông điệp: `"Hệ thống Backend hiện tại chưa cung cấp API endpoint cho Sơ đồ bãi xe (/api/v1/parking/slots/ - HTTP 404 Not Found). Giao diện tuân thủ chế độ Strict API, không fallback về dữ liệu mock."`
      - Nếu lỗi kết nối mạng / server offline (`err.code === "API_UNAVAILABLE"`): Gán thông điệp: `"Không thể kết nối tới máy chủ backend. Vui lòng kiểm tra lại dịch vụ backend."`
    - Gán `slots = []` (KHÔNG gán `fullParkingLotData`).
    - Cung cấp hàm `retry()` để người dùng có thể kích hoạt thử lại.

### 4.3. Cải Tiến UI / UX Trên Trang `ParkingLotManagement.jsx`
1. **Hiển thị Banner Cảnh Báo Lỗi API (Strict Error Banner)**:
   - Khi `error` có giá trị, hiển thị Banner màu đỏ/amber ngay dưới `PageHeader`:
     - Biểu tượng Lucide: `AlertTriangle` hoặc `ServerCrash`.
     - Tiêu đề: `"Không thể tải dữ liệu bãi xe từ máy chủ"`.
     - Nội dung chi tiết: Hiển thị nguyên văn thông báo lỗi và trạng thái HTTP.
     - Nút hành động: "Thử lại kết nối" (`retry`).
2. **Hiển thị Trạng thái Trống / Lỗi (Empty / Error State)**:
   - Khi ma trận ô đỗ không có dữ liệu do lỗi API, hiển thị một `EmptyState` tinh gọn trong khung canvas thay vì để vỡ giao diện.
3. **Loại Bỏ Hoàn Toàn Import Mock Data**:
   - Xóa `import { fullParkingLotData } from "../mocks/parkingLotData";` khỏi `ParkingLotManagement.jsx`.

---

## 5. Bảng Phân Chia Nhiệm Vụ Cho 3 Subagents

Dựa trên kết quả khảo sát, đây là bảng hướng dẫn chi tiết cho từng subagent:

| Subagent | Nhiệm vụ chính | Các tệp cần xử lý | Hành động kỹ thuật cụ thể |
|---|---|---|---|
| **Subagent 1** (Icon & UI/UX) | Sửa và đồng nhất icon UI/UX | `ParkingLotManagement.jsx`, `ParkingLotStatsCards.jsx`, `ParkingLotFilters.jsx`, `ParkingSlotMatrix.jsx`, `SlotDetailPanel.jsx`, `ParkingLotStructureAndActivity.jsx` | - Thay toàn bộ icon inline SVG và icon emoji (🚗, ⏱, ⚠️, ✓, ✏️, 🗑️, ⚙) bằng Lucide icons (`Car`, `Clock`, `Wrench`, `CheckCircle2`, `Download`, `Plus`, `Search`, `RotateCcw`, `Edit3`, `Trash2`, `Settings`, `AlertTriangle`).<br>- Xóa `import React from "react"` ở tất cả các file để fix ESLint.<br>- Tách `renderSlotCard` ra khỏi `ParkingSlotMatrix.jsx` để fix lỗi Fast Refresh lint. |
| **Subagent 2** (API Contract & Integration) | Kết nối API Backend thực tế, xử lý lỗi không mock fallback | Tạo mới `services/parkingLotService.js`, `hooks/useParkingLot.js`, chỉnh sửa `ParkingLotManagement.jsx` | - Tạo `parkingLotService.js` với các API REST chuẩn hóa theo hợp đồng Backend.<br>- Tạo `useParkingLot.js` gọi API thực tế, chặn đứng mọi mock fallback, xử lý lỗi 404/mạng.<br>- Cập nhật `ParkingLotManagement.jsx` sử dụng `useParkingLot`, render Error Banner thông báo lỗi kết nối rõ ràng.<br>- Đảm bảo thư mục `parking_management_backend/` nguyên vẹn 100%. |
| **Subagent 3** (Interactions & Actions) | Hoàn thiện tương tác cho nút bấm & bộ lọc | `ParkingLotFilters.jsx`, `SlotDetailPanel.jsx`, `ParkingLotManagement.jsx`, `ParkingLotStructureAndActivity.jsx` | - Đấu nối state của bộ lọc tầng (`selectedFloor`), khu vực (`selectedZone`), từ khóa tìm kiếm (`searchQuery`), trạng thái (`statusFilter`), loại xe (`vehicleTypeFilter`) vào hook.<br>- Hiện thực hóa chức năng nút "Đặt lại bộ lọc" (`onResetFilters`).<br>- Đấu nối các nút cập nhật trạng thái trong `SlotDetailPanel` gọi hàm cập nhật của hook.<br>- Thêm toast/modal thông báo khi người dùng click "+ Thêm ô đỗ xe", "Xuất báo cáo", "Sửa", "Xóa", "Cấu hình". |
