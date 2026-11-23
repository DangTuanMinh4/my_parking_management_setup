# Báo Cáo Phân Tích Hiện Trạng & Đề Xuất Chuẩn Hóa Lucide Icons Cho Trang Sơ Đồ Bãi Đậu Xe

**Dự án**: Smart Mobility Parking Lot Management System (`parking_management_frontend`)  
**Mục tiêu**: Khảo sát hiện trạng sử dụng icon, inline SVG, emoji trên trang Sơ đồ bãi đậu xe (`ParkingLotManagement.jsx`) và 5 sub-components trực thuộc, xây dựng bảng đối chiếu và đặc tả chuẩn hóa đồng nhất sang thư viện `lucide-react`.  
**Ngày thực hiện**: 2026-11-04  
**Trạng thái**: Hoàn tất khảo sát

---

## 1. Vị Trí Các Tệp Mã Nguồn Liên Quan

| Tên Component | Đường Dẫn Tuyệt Đối / Tương Đối | Vai Trò & Phạm Vi |
|---|---|---|
| **Trang chính (Page)** | `parking_management_frontend/src/pages/ParkingLotManagement.jsx` | Khung điều phối, tiêu đề trang `PageHeader`, 4 nút thao tác chính, tích hợp bộ lọc, ma trận và chi tiết. |
| **Thẻ thống kê (Stats)** | `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStatsCards.jsx` | 4 thẻ chỉ số nhanh: Tổng ô, Ô trống, Đang sử dụng, Đặt trước/Bảo trì. |
| **Bộ lọc tìm kiếm (Filters)** | `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotFilters.jsx` | 6 bộ lọc (Bãi, Tầng, Khu, Tìm kiếm, Trạng thái, Loại xe) và 2 nút hành động (Reset bộ lọc, Chế độ sửa sơ đồ). |
| **Sơ đồ ma trận (Matrix)** | `parking_management_frontend/src/components/ParkingLotManagement/ParkingSlotMatrix.jsx` | Ma trận canvas tối hiển thị các dãy ô A, B, làn xe nội bộ, hướng vào/ra và thẻ từng ô đỗ. |
| **Panel chi tiết (Detail)** | `parking_management_frontend/src/components/ParkingLotManagement/SlotDetailPanel.jsx` | Hiển thị chi tiết ô được chọn, 2 nút hành động (Sửa, Xóa) và 4 nút cập nhật nhanh trạng thái. |
| **Cấu trúc & Hoạt động** | `parking_management_frontend/src/components/ParkingLotManagement/ParkingLotStructureAndActivity.jsx` | Bảng quản lý phân tầng/phân khu (nút Cấu hình, Sửa, Xóa) và danh sách nhật ký hoạt động. |
| **Barrel Export** | `parking_management_frontend/src/components/ParkingLotManagement/index.js` | Xuất tập trung 5 sub-components. |
| **Hạ tầng Icon dùng chung** | `parking_management_frontend/src/components/common/icon/` (`Icon.jsx`, `iconConstants.js`) | Component `<Icon />` chuẩn hóa và từ điển `ICON_REGISTRY`. |

---

## 2. Hiện Trạng Thư Viện & Kiểu Biểu Tượng Đang Dùng

### 2.1. Kiểm tra cấu hình `package.json`
- `parking_management_frontend/package.json` đã cài đặt:
  ```json
  "dependencies": {
    "lucide-react": "^1.65.0",
    "react": "^19.2.8",
    "react-dom": "^19.2.8",
    "tailwindcss": "^4.3.3"
  }
  ```
- **Kết luận**: Thư viện `lucide-react` đã có sẵn trong `dependencies`, không cần cài thêm package nào khác. Đã kiểm tra runtime xác thực 100% các icon đề xuất đều tồn tại hợp lệ trong gói cài đặt (`ALL_ICONS_VALID`).

### 2.2. Hiện trạng thực tế tại cụm Sơ đồ bãi đậu xe
Mặc dù `lucide-react` đã được cài đặt và được dùng ở một số màn hình khác (`CustomerManagement`, `VehicleManagement`), toàn bộ trang `ParkingLotManagement` và 5 sub-components **hoàn toàn chưa import hay sử dụng bất kỳ Lucide icon nào**!
Hiện trạng đang bị phân mảnh nghiêm trọng qua 4 hình thức:
1. **Inline raw `<svg>` tự vẽ thủ công**: 7 vị trí (Nút Xuất báo cáo, 4 thẻ StatCard, ô Tìm kiếm, nút Đặt lại bộ lọc, nút Chế độ sửa). Các SVG này không đồng nhất về stroke-width, viewBox và kích thước.
2. **Ký tự Emoji hệ điều hành**: 5 vị trí (`🚗` biểu diễn ô có xe, `⏱` biểu diễn ô đã đặt, `⚠️` biểu diễn ô bảo trì, `✏️ Sửa`, `🗑️ Xóa`). Emoji hiển thị khác nhau trên Windows, macOS, iOS, Android, làm vỡ tính chuyên nghiệp của giao diện dashboard.
3. **Ký tự Unicode & văn bản thô**: 6 vị trí (`✓` dấu tích ô trống, `➔` hướng vào, `←` làn xe nội bộ, `→` lối ra, `⚙ Cấu hình`, tiền tố dấu `+` trong các nút "+ Thêm tầng", "+ Thêm khu", "+ Thêm ô đỗ xe").
4. **Nút bấm thiếu icon minh họa**: Các nút thao tác nhỏ như `Sửa`, `Xóa` trong danh mục cấu trúc bãi chưa có icon.

---

## 3. Bảng Danh Mục Chi Tiết Từng Vị Trí & Đề Xuất Chuẩn Hóa

### 3.1. `ParkingLotManagement.jsx` (Trang chính & Header)

| Dòng | Phần tử / Chức năng | Hiện trạng | Ngữ cảnh trực quan | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **118–128** | Nút "Xuất báo cáo" | Inline raw `<svg>` | Nút thứ cấp xuất dữ liệu / báo cáo | `Download` hoặc `FileDown` | `<Button variant="secondary" size="sm" icon={<Download className="w-3.5 h-3.5" />} className="cursor-pointer">Xuất báo cáo</Button>` |
| **129–131** | Nút "+ Thêm tầng" | Text `+ Thêm tầng` | Nút tạo tầng mới | `Plus` | `<Button variant="secondary" size="sm" icon={<Plus className="w-3.5 h-3.5" />} className="cursor-pointer">Thêm tầng</Button>` |
| **132–134** | Nút "+ Thêm khu" | Text `+ Thêm khu` | Nút tạo khu vực mới | `Plus` | `<Button variant="secondary" size="sm" icon={<Plus className="w-3.5 h-3.5" />} className="cursor-pointer">Thêm khu</Button>` |
| **135–137** | Nút "+ Thêm ô đỗ xe" | Text `+ Thêm ô đỗ xe` | CTA chính tạo ô đỗ | `Plus` | `<Button variant="primary" size="sm" icon={<Plus className="w-3.5 h-3.5" />} className="cursor-pointer">Thêm ô đỗ xe</Button>` |

---

### 3.2. `ParkingLotStatsCards.jsx` (Thẻ thống kê nhanh)

| Dòng | Thẻ chỉ số | Hiện trạng | Ngữ cảnh trực quan & Ý nghĩa | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **12–21** | "Tổng ô đỗ trong khu" | Inline `<svg>` 4 ô vuông thô | Tổng số ô trong ma trận / khu vực | `LayoutGrid` (hoặc `ParkingSquare`) | `icon={<LayoutGrid className="w-5 h-5" />}` |
| **29–33** | "Ô trống" | Inline `<svg>` checkmark | Vị trí khả dụng sẵn sàng đón xe | `CheckCircle2` (hoặc `CircleCheck`) | `icon={<CheckCircle2 className="w-5 h-5" />}` |
| **41–45** | "Đang sử dụng" | Inline `<svg>` check-in-circle (sai ngữ nghĩa!) | Vị trí hiện có phương tiện đang đỗ | `Car` (hoặc `CarFront`) | `icon={<Car className="w-5 h-5" />}` |
| **53–57** | "Đặt trước / Bảo trì" | Inline `<svg>` đồng hồ tròn | Vị trí tạm giữ chỗ hoặc đang sửa chữa | `Clock` (hoặc `Clock3`) | `icon={<Clock className="w-5 h-5" />}` |

---

### 3.3. `ParkingLotFilters.jsx` (Thanh công cụ & Bộ lọc)

| Dòng | Phần tử / Chức năng | Hiện trạng | Ngữ cảnh trực quan | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **60–69** | Input "Tìm kiếm" | Inline `<svg>` kính lúp | Tiền tố tìm kiếm mã ô / biển số | `Search` | `leftIcon={<Search className="w-3.5 h-3.5 text-slate-400" />}` |
| **98–105** | Nút "Đặt lại bộ lọc" | Inline `<svg>` mũi tên xoay | Reset toàn bộ giá trị bộ lọc | `RotateCcw` (hoặc `RefreshCw`) | `<Button variant="secondary" size="sm" icon={<RotateCcw className="w-3.5 h-3.5" />} onClick={onResetFilters}>Đặt lại bộ lọc</Button>` |
| **116–123** | Nút "Chế độ chỉnh sửa sơ đồ" | Inline `<svg>` bút chì | Chuyển chế độ tương tác sửa sơ đồ | `Pencil` (hoặc `SquarePen`) | `<Button variant="outline" size="sm" icon={<Pencil className="w-3.5 h-3.5" />}>Chế độ chỉnh sửa sơ đồ</Button>` |
| *(Mở rộng R3)* | Nút chuyển chế độ xem (Matrix / List view) | *(Chưa có trong UI)* | Chuyển đổi giữa sơ đồ lưới trực quan và bảng danh sách ô | `LayoutGrid` (cho Matrix) và `List` (cho List view) | `<Button variant={viewMode === 'matrix' ? 'primary' : 'outline'} icon={<LayoutGrid className="w-3.5 h-3.5" />} />` |

---

### 3.4. `ParkingSlotMatrix.jsx` (Sơ đồ ma trận & Thẻ ô đỗ)

| Dòng | Phần tử / Ngữ cảnh | Hiện trạng | Ý nghĩa & Trạng thái | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **19–21** | Ô `AVAILABLE` (Trống) | Ký tự Unicode `✓` | Ô đỗ còn trống, sẵn sàng tiếp nhận xe | `Check` | `<div className="w-6 h-6 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center"><Check className="w-3.5 h-3.5" /></div>` |
| **43** | Ô `OCCUPIED` (Đang đỗ) | Emoji `🚗` | Phương tiện đang đỗ trong ô | `Car` (hoặc `Zap` nếu xe điện sạc) | `<Car className="w-6 h-6 text-rose-400" />` |
| **64** | Ô `RESERVED` (Đặt trước) | Emoji `⏱` | Ô đã được khách hàng đặt trước lịch | `Clock` | `<Clock className="w-5 h-5 text-amber-400" />` |
| **80** | Ô `MAINTENANCE` (Bảo trì) | Emoji `⚠️` | Ô đỗ đang bảo trì cảm biến / thiết bị | `Wrench` (hoặc `AlertTriangle`) | `<Wrench className="w-5 h-5 text-slate-400" />` |
| **133–135** | Dãy A - Hướng vào | Ký tự Unicode `➔` | Chỉ dẫn hướng luồng xe vào | `ArrowRight` | `<ArrowRight className="w-3.5 h-3.5 inline mr-1 text-emerald-400" />` |
| **153** | Làn đường nội bộ (Driveway) | Ký tự Unicode `←` | Chỉ dẫn hướng làn xe chạy nội bộ | `ArrowLeft` | `<ArrowLeft className="w-3.5 h-3.5 inline mr-1 text-slate-400" />` |
| **159** | Lối ra khỏi bãi | Ký tự Unicode `→` | Chỉ dẫn hướng lối ra | `ArrowRight` | `<ArrowRight className="w-3.5 h-3.5 inline ml-1 text-slate-400" />` |
| **167** | Cảm biến siêu âm Active | Text thuần | Trạng thái cảm biến IoT hoạt động | `Radio` (hoặc `Wifi`) | `<Radio className="w-3 h-3 inline mr-1 text-blue-400" />` |

---

### 3.5. `SlotDetailPanel.jsx` (Panel thông tin chi tiết ô đỗ)

| Dòng | Phần tử / Chức năng | Hiện trạng | Ngữ cảnh trực quan | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **113** | Nút "Sửa" | Emoji `✏️ Sửa` | Thao tác mở form chỉnh sửa thông tin ô | `Pencil` | `<Button variant="primary" size="sm" fullWidth icon={<Pencil className="w-3.5 h-3.5" />} className="cursor-pointer">Sửa</Button>` |
| **121** | Nút "Xóa" | Emoji `🗑️ Xóa` | Thao tác xóa ô đỗ sau khi xác nhận | `Trash2` | `<Button variant="dangerOutline" size="sm" fullWidth icon={<Trash2 className="w-3.5 h-3.5" />} className="cursor-pointer">Xóa</Button>` |
| **144** | Cập nhật nhanh: Ô trống | Chấm tròn xanh | Đặt trạng thái về AVAILABLE | `CheckCircle2` | `<CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />` thay cho dot hoặc đi kèm |
| **157** | Cập nhật nhanh: Có xe đỗ | Chấm tròn đỏ | Đặt trạng thái về OCCUPIED | `Car` | `<Car className="w-3.5 h-3.5 text-rose-600" />` |
| **170** | Cập nhật nhanh: Đặt trước | Chấm tròn vàng | Đặt trạng thái về RESERVED | `Clock` | `<Clock className="w-3.5 h-3.5 text-amber-600" />` |
| **183** | Cập nhật nhanh: Bảo trì | Chấm tròn xám | Đặt trạng thái về MAINTENANCE | `Wrench` (hoặc `AlertTriangle`) | `<Wrench className="w-3.5 h-3.5 text-slate-500" />` |

---

### 3.6. `ParkingLotStructureAndActivity.jsx` (Cấu trúc & Hoạt động)

| Dòng | Phần tử / Chức năng | Hiện trạng | Ngữ cảnh trực quan | Đề xuất Lucide Icon | Mã JSX thay thế |
|---|---|---|---|---|---|
| **23** | Nút "Cấu hình" | Ký tự `⚙ Cấu hình` | Mở cài đặt cấu trúc tầng/khu vực | `Settings` | `<Button variant="secondary" size="sm" icon={<Settings className="w-3.5 h-3.5" />} className="cursor-pointer">Cấu hình</Button>` |
| **47** | Nút "Sửa" trong danh sách | Text `Sửa` không icon | Sửa cấu hình tầng/khu vực | `Pencil` | `<Button variant="primary" size="xs" icon={<Pencil className="w-3 h-3" />} className="cursor-pointer">Sửa</Button>` |
| **53** | Nút "Xóa" trong danh sách | Text `Xóa` không icon | Xóa cấu hình tầng/khu vực | `Trash2` | `<Button variant="dangerOutline" size="xs" icon={<Trash2 className="w-3 h-3" />} className="cursor-pointer">Xóa</Button>` |
| **65–70** | Tiêu đề "Hoạt động gần đây" | Text thuần | Nhật ký hoạt động hệ thống | `Activity` (hoặc `History`) | Có thể bổ sung `<Activity className="w-4 h-4 text-blue-600 inline mr-1.5" />` |

---

## 4. Chuẩn Hóa Phân Loại Phương Tiện & Trạng Thái Theo Nghiệp Vụ

Nhằm phục vụ hiển thị động khi kết nối API Backend thực tế (Requirement R2 & R3), bảng phân loại biểu tượng khuyến nghị như sau:

### 4.1. Biểu tượng theo loại phương tiện (`vehicleType` / `slotType`)
- **Ô tô tiêu chuẩn (`STANDARD`)**: `Car` (`lucide-react`)
- **Xe ưu tiên (`PRIORITY`)**: `Car` kết hợp badge hoặc icon `ShieldAlert` / `Star`
- **Ô sạc điện (`EV_CHARGING`)**: `Zap` hoặc `BatteryCharging`
- **Xe máy (`MOTORCYCLE` - nếu mở rộng)**: `Bike`
- **Xe tải (`TRUCK` - nếu mở rộng)**: `Truck`

### 4.2. Biểu tượng theo trạng thái ô đỗ (`slotStatus`)
- **`AVAILABLE` (Trống)**: `Check` (trong matrix) hoặc `CheckCircle2` (trong stats/quick-actions). Màu sắc: `text-emerald-400` / `bg-emerald-500`.
- **`OCCUPIED` (Đang đỗ)**: `Car`. Màu sắc: `text-rose-400` / `bg-rose-500`.
- **`RESERVED` (Đã đặt trước)**: `Clock`. Màu sắc: `text-amber-400` / `bg-amber-500`.
- **`MAINTENANCE` (Bảo trì)**: `Wrench`. Màu sắc: `text-slate-400` / `bg-slate-500`.

---

## 5. Chiến Lược Triển Khai Cho Subagent Tiếp Theo

Có 2 hướng tiếp cận kỹ thuật tương thích hoàn toàn với kiến trúc hiện có:

### Cách 1: Import trực tiếp từ `lucide-react` (Khuyến nghị cho tính linh hoạt)
Trong từng component, import trực tiếp các icon cần dùng:
```jsx
import {
  Download,
  Plus,
  LayoutGrid,
  CheckCircle2,
  Car,
  Clock,
  Search,
  RotateCcw,
  Pencil,
  Trash2,
  Wrench,
  Check,
  ArrowRight,
  ArrowLeft,
  Settings,
} from "lucide-react";
```
Cách này tận dụng Tree-shaking của Vite/Rolldown, định dạng kích thước và màu sắc Tailwind linh hoạt (`className="w-4 h-4 text-slate-500"`). Nút `Button` có sẵn prop `icon={<IconComponent className="..." />}` sẽ render tự động bên trái chữ với lề căn chỉnh chuẩn (`mr-1.5`).

### Cách 2: Bổ sung vào `ICON_REGISTRY` (`src/components/common/icon/iconConstants.js`)
Thêm các key mới vào từ điển hệ thống:
```javascript
export const ICON_REGISTRY = {
  // đã có: edit, delete, add, search, view, settings, close, check, vehicle, user, chevronDown, refresh, warning
  download: Download,
  layoutGrid: LayoutGrid,
  clock: Clock,
  wrench: Wrench,
  arrowRight: ArrowRight,
  arrowLeft: ArrowLeft,
  rotateCcw: RotateCcw,
};
```
Sau đó sử dụng qua `<Button icon="download">Xuất báo cáo</Button>` hoặc `<Icon name="download" size="sm" />`.

---

## 6. Lưu Ý Khi Refactor (ESLint & React 19)

1. **Bỏ `import React from "react"` thừa**:
   Hiện tại trong `ParkingLotFilters.jsx`, `ParkingLotStatsCards.jsx`, `ParkingLotStructureAndActivity.jsx`, `ParkingSlotMatrix.jsx`, `SlotDetailPanel.jsx`, đều có dòng `import React from "react";`. Dưới cấu hình ESLint của dự án, dòng này gây ra 5 lỗi `no-unused-vars`. Khi refactor icon, hãy xóa import thừa này.
2. **Cảnh báo Fast Refresh trong `ParkingSlotMatrix.jsx`**:
   `ParkingSlotMatrix.jsx` export đồng thời `renderSlotCard` và default export component `ParkingSlotMatrix`, gây ra cảnh báo `react-refresh/only-export-components`. Khi thực hiện, nên giữ `renderSlotCard` nội bộ hoặc tách riêng helper nếu cần.
3. **Đảm bảo không phá vỡ UI/UX nền tối của canvas**:
   Các icon trên canvas sơ đồ ô đỗ (dãy A, dãy B, đường nội bộ) nằm trên nền tối (`#0B132B`). Hãy giữ nguyên các class màu sắc tương phản cao: `text-emerald-400`, `text-rose-400`, `text-amber-400`, `text-slate-400`, `text-blue-400`.
