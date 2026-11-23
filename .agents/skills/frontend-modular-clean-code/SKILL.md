---
name: frontend-modular-clean-code
description: >-
  Quy tắc và hướng dẫn tổ chức mã nguồn Frontend (React 19 + Tailwind) theo
  hướng module hóa, ngăn chặn file quá tải (> 200 dòng), tận dụng triệt để
  components/common, phân tách concerns rõ ràng ngay từ đầu thay vì đợi hoàn
  thành mới refactor.
---
# Frontend Modular & Clean Code Standards

Skill này hướng dẫn quy chuẩn tổ chức code khi xây dựng hoặc cập nhật các tính năng Frontend trong `parking_management_frontend/`. 
Mục tiêu cốt lõi: **Giữ file nhỏ gọn (< 200 dòng), tái sử dụng tối đa Design System có sẵn (`components/common`), phân tầng sạch sẽ, dễ bảo trì và tránh gây nghẽn context khi AI bảo trì về sau.**

---

## 1. Ngưỡng Giới Hạn Code (Hard Limits)

- **Kích thước File Component / Page**: Tối đa **150 - 200 dòng**. Nếu vượt quá 200 dòng, bắt buộc phải tách.
- **Kích thước Custom Hook**: Tối đa **120 dòng**.
- **Kích thước Helper / Service / Schema**: Tối đa **100 dòng**.

---

## 2. Bản Đồ Cấu Trúc Toàn Diện Của Frontend (`src/`)

Dự án đã có cấu trúc thư mục được thiết kế bài bản. Luôn đặt file vào đúng vị trí ngay từ đầu:

```
src/
├── components/
│   ├── common/             # THƯ VIỆN DÙNG CHUNG CỐT LÕI (Không viết lại nếu đã có ở đây!)
│   │   ├── badge/          # StatusBadge, DotBadge...
│   │   ├── button/         # Button, IconButton...
│   │   ├── icon/           # Icon svg wrapper & icons hệ thống
│   │   ├── modal/          # BaseModal, ConfirmModal...
│   │   ├── table/          # DataTable, TableActions, TablePagination...
│   │   ├── EmptyState.jsx  # Hiển thị khi không có dữ liệu
│   │   ├── FilterSelect.jsx# Dropdown bộ lọc chuẩn
│   │   ├── LoadingSpinner.jsx # Con quay loading
│   │   ├── PageToolbar.jsx # Toolbar tìm kiếm và nút action đầu trang
│   │   └── Pagination.jsx  # Phân trang chuẩn
│   ├── layout/             # AppLayout, AppTopHeader...
│   └── <Feature>/          # Sub-components đặc thù của tính năng (VehicleManagement, CustomerManagement...)
├── constants/              # HẰNG SỐ CỐ ĐỊNH: Config màu sắc Tailwind, enum, filter options, initial blank state
├── context/                # Contexts dùng chung (ToastContext, AuthContext...)
├── hooks/                  # Custom hooks: usePagination, useVehicleData, useDebounce...
├── mocks/                  # Dữ liệu giả lập test offline (nếu có)
├── pages/                  # Page Container (Orchestrator chỉ ghép nối các block, < 200 dòng)
├── schemas/                # Validation schema & Data contracts (vehicleSchema.js, customerSchema.js...)
├── services/               # DATA ACCESS LAYER (apiClient.js, authService.js, vehicleService.js, customerService.js...)
└── utils/                  # HÀM XỬ LÝ & CHUYỂN ĐỔI DỮ LIỆU (Pure functions, formatters, domain mappers)
    ├── vehicle/            # Domain-specific mappers cho Vehicle (vehicleFormMapper.js, vehicleApiMapper.js)
    ├── customer/           # Domain-specific mappers cho Customer (customerFormMapper.js)
    ├── parking/            # Domain-specific mappers & calculator (parkingFeeCalculator.js, plateScanMapper.js)
    ├── formatDateTime.js   # Format ngày giờ dùng chung
    └── plateAutoDetect.js  # Nhận diện biển số
```

---

## 3. Quy Tắc Tái Sử Dụng Thư Viện Dùng Chung (`components/common`)

> [!IMPORTANT]
> **Check `components/common/` trước khi tự viết thẻ HTML thuần.**
> Dự án đã có sẵn Design System thu nhỏ. Tuyệt đối **KHÔNG TỰ VIẾT LẠI**:

1. **Bảng dữ liệu**: Dùng `DataTable` từ `components/common/table` thay vì viết thẻ `<table>` thô.
2. **Nút bấm**: Dùng `Button` từ `components/common/button` thay vì `<button className="...">`.
3. **Thanh Toolbar / Tìm kiếm**: Dùng `PageToolbar` và `FilterSelect` thay vì tự tạo `<input>` và `<select>` rời rạc.
4. **Modal / Popups**: Dùng `BaseModal` hoặc `ConfirmModal` thay vì tự dựng overlay `fixed inset-0`.
5. **Loading & Empty State**: Dùng `LoadingSpinner` và `EmptyState`.
6. **Badge trạng thái**: Dùng `StatusBadge` kết hợp config từ `constants/`.
7. **Thông báo hệ thống**: Dùng `useToast` từ `context/ToastContext` thay vì `alert()` hoặc toast ngoài.

---

## 4. Chi Tiết Từng Phân Tầng

### A. Tầng Hằng số & Lookups (`src/constants/`)
- Cấm hardcode class Tailwind (màu sắc, viền, background) rải rác bên trong JSX.
- **Tập trung hóa chuỗi hiển thị mặc định (Default Fallback Labels & System Placeholders)**: Mọi chuỗi nhãn trạng thái fallback mặc định khi chưa có dữ liệu (ví dụ: `Chưa có vị trí`, `Tự động phân bổ khi check-in`, `Vé lượt`) phải được gom thành hằng số export tại `src/constants/<feature>Constants.js`. Tuyệt đối không lặp lại các magic strings này rải rác qua nhiều files (Mapper, Modal, Detail Cards, FormFields).
- Mọi mảng filter (ví dụ: `STATUS_FILTER_OPTIONS`, `TICKET_FILTER_OPTIONS`) và state khởi tạo form (`INITIAL_FORM_STATE`) định nghĩa tại đây.
- **Lưu ý**: Chỉ lưu trữ giá trị cố định (literal/enums). Các hàm biến đổi logic hoặc mapper KHÔNG đặt tại constants mà chuyển sang `src/utils/<domain>/`.

### B. Tầng Tiện Ích & Mappers (`src/utils/`)
- **Phân nhóm theo Domain**: Nhằm tránh `utils/` trở thành thư mục chứa mọi thứ hỗn độn, các hàm biến đổi dữ liệu theo nghiệp vụ (Domain Mappers & Calculators) được nhóm theo thư mục domain con:
  - `src/utils/vehicle/`: Mappers cho Vehicle (`vehicleFormMapper.js`, `vehicleApiMapper.js`).
  - `src/utils/customer/`: Mappers cho Customer (`customerFormMapper.js`).
  - `src/utils/parking/`: Mappers & công cụ tính toán (`parkingFeeCalculator.js`, `plateScanMapper.js`).
  - `src/utils/formatDateTime.js`: Format ngày tháng năm, ISO dates (dùng chung).
- **Chuẩn hóa Data Key đồng bộ giữa Entity và Form (Data Key Alignment)**:
  - Tránh tình trạng phân mảnh data key giữa các tầng (ví dụ: entity dùng `model`, form lại dùng `modelName`, backend trả `model_name`).
  - Toàn bộ phía Frontend (Entity model, Form State, Zod Schema, UI Fields) phải **thống nhất cùng một key chuẩn duy nhất** (ví dụ: `model`).
  - Việc chuyển đổi giữa payload Backend (`model_name`) và Frontend Entity (`model`) chỉ diễn ra **duy nhất tại Mapper** (`toCreatePayload`, `toUpdatePayload`, `mapVehicleSearchItem`, `mapFormDataToVehicleEntity`).
  - Modal không tự ghép nối object thủ công trong hàm `onSubmit` mà giao phó toàn bộ cho Form Mapper chuyên trách (`mapFormDataToVehicleEntity`).
- **Trách nhiệm của Mapper & Calculator**: Nhận entity/data thô và trả về cấu trúc đã format hoặc kết quả tính toán chuẩn, không chứa side-effects, không gọi API, không dùng React hooks.

### C. Tầng Data Access & Dịch Vụ API (`src/services/`)
- Toàn bộ giao tiếp HTTP tới Backend REST API được tập trung duy nhất tại `src/services/` (`apiClient.js`, `authService.js`, `vehicleService.js`, `customerService.js`, `parkingSessionService.js`, `dashboardService.js`, `plateScanService.js`).
- Không duy trì thư mục `src/features/` chỉ để chứa service, tránh tạo ra sự mơ hồ và trùng lặp với `src/services/`.
- **Trách nhiệm duy nhất của Service**: Thực hiện HTTP request, serialize/deserialize qua các mappers từ `src/utils/<domain>/` và trả về dữ liệu chuẩn cho Hooks hoặc Pages.

### D. Tầng State & Hydration (`src/hooks/`)
- Tách toàn bộ `useEffect`, `useState` fetch API và logic kết hợp dữ liệu (hydrate) sang custom hook.
- Phải hỗ trợ: `isLoading`, `error`, và hàm `reload()`.
- **Giới hạn quy mô Hook**: Hook tối đa **120 dòng**. Nếu luồng nghiệp vụ lớn (như camera/OCR streaming hay workflow đa bước), phải tách thành các sub-hooks chuyên biệt (ví dụ: `useCameraStream`, `useFrameRecognition`, `useWorkflowSteps`).

### E. Tầng Sub-components (`src/components/<Feature>/`)
- Tách các modal thêm/sửa, card thống kê (StatCard), hoặc badge đặc thù vào thư mục con của feature đó.
- Component nhận props rõ ràng, không chứa logic gọi API trực tiếp (để page hoặc hook điều phối).
- **Tập trung hóa xuất khẩu bằng `index.js` (Barrel File)**:
  - Mỗi thư mục `src/components/<Feature>/` nên có một file `index.js` đóng vai trò barrel file (export tất cả sub-components).
  - Giúp việc import tại Page Container hoặc các module khác luôn gọn gàng, đồng bộ (ví dụ: `import { VehicleTable, VehicleStatsCards } from "../components/VehicleManagement";` thay vì 10 dòng import riêng lẻ từng file).
- **Phân tách cấu trúc dữ liệu trong Modal/Form**:
  - Tuyệt đối không nhồi nhét cấu trúc dữ liệu thô, state form khởi tạo, Zod schema validation, hoặc các combobox phụ thuộc vào cùng 1 file Modal.
  - Tách Schema xác thực dữ liệu ra `src/schemas/<feature>Schema.js`.
  - Tách Initial state ra `src/constants/<feature>Constants.js`.
  - Tách hàm chuyển đổi dữ liệu (Mapper) ra `src/utils/<feature>/<feature>FormMapper.js`.
  - Tách các thành phần chọn lọc phụ (Searchable Combobox, Tag List, Nested Dropdown) thành sub-components độc lập trong `src/components/<Feature>/`.
  - Tách cụm Form Fields nếu form có nhiều hơn 5 trường nhập liệu (`<Feature>FormFields.jsx`).

### F. Nguyên Tắc Phân Rã Giao Diện Phức Tạp (Complex UI Decomposition)
Khi giao diện có luồng tương tác nhiều bước, nhiều trạng thái hoặc cấu trúc hiển thị dày đặc:
- **Tách 3 thành phần rõ vai trò**:
  1. **Vỏ điều phối (Shell/Container)**: Quản lý vòng đời (mở/đóng), chuyển đổi trạng thái hiển thị (steps, view modes) và footer actions.
  2. **Các khối con độc lập (Sub-views/Steps/Sections)**: Chỉ tập trung render nội dung của từng phần cụ thể và nhận callbacks.
  3. **Custom Hook quản lý logic**: Gom toàn bộ state máy (state machine), tính toán và tương tác API ra ngoài component hiển thị.

### G. Tầng Tiện Ích Độc Lập & Thuật Toán Thuần (`src/utils/`)
- Khi một hàm/utility xử lý thuật toán phức tạp hoặc logic domain lớn vượt quá kích thước tinh gọn:
  - Phân rã thành module thư mục riêng theo từng trách nhiệm (nhóm luật/regex, hàm tiền xử lý dữ liệu, và pipeline điều phối chính).
  - Giữ các hàm utility luôn là pure functions (không side-effect, không hook React).

### H. Nguyên Tắc Khử Trùng Lặp (Single Source of Truth / Deduping)
- Mỗi tính năng, tiện ích, modal hay helper chỉ duy trì **duy nhất một phiên bản** trong toàn bộ dự án.
- Khi cần dùng một tính năng ở nhiều màn hình (ví dụ: tiện ích quét, bộ xuất file, bảng tra cứu):
  - Tuyệt đối không sao chép hoặc tạo thêm bản thứ hai trong thư mục feature khác.
  - Quy hoạch về thư mục dùng chung (`components/common/` hoặc thư mục domain tập trung) và tái sử dụng qua props/hook.

### I. Tầng Page Container (`src/pages/`)
- Chỉ làm nhiệm vụ Orchestration:
  1. Lấy dữ liệu từ custom hook.
  2. Bắt các event mở/đóng modal, xác nhận xóa.
  3. Render `PageToolbar`, `DataTable`, `Modals`.

### J. Kỹ Thuật Phòng Ngừa Lỗi React & Mapper Runtime (React & Mapper Resilience)
- **Chống render Object thô vào JSX**:
  - Tránh truyền trực tiếp object (như `{ value, label }` từ dropdown hay API) vào thẻ JSX.
  - Các common components (`DataTable`, `StatusBadge`, `FilterSelect`) luôn bóc tách `.label ?? .name ?? .value` hoặc kiểm tra `isValidElement` trước khi render.
- **Mapper Hygiene & Chống Shadowing**:
  - Tách domain extraction helpers (`extractCustomer`, `extractTicket`, `extractParkingSlot`) dùng chung.
  - Single Source of Truth: Khi ánh xạ cả flat keys (`customerId`, `customerName`) và nested object (`customer`), hãy bóc tách domain con trước, rồi map flat keys từ nested object đó.
  - Cấm `...base` rồi lại ghi đè lặp lại các keys trùng lặp.
- **Media & Image Fallback an toàn**:
  - Sanitize URL media ở mapper: loại bỏ các chuỗi dạng `"null"`, `"undefined"`, `"[object Object]"`, trả về `null`.
  - Component hiển thị ảnh luôn kiểm tra `if (!imageUrl)` và render placeholder, tuyệt đối không dùng `console.error` báo động đỏ cho lỗi 404 ảnh thiếu trên disk.
- **Trật tự khai báo React & Chống TDZ (Temporal Dead Zone)**:
  - Khai báo biến/hàm pure hoặc callback `useCallback` TRƯỚC khi đưa vào dependency array hoặc thân của `useEffect`.
  - Trật tự chuẩn: `State/Refs` -> `Pure Helper Functions` -> `Action Callbacks (useCallback)` -> `Side Effects (useEffect)` -> `JSX Render`.
- **Dependencies Array của Hooks**:
  - Độ dài dependency array của `useEffect`, `useMemo`, `useCallback` phải cố định (không spread `[...deps]`, không mảng động).

---

## 5. Checklist Toàn Diện Trước Khi Hoàn Thành Code (Comprehensive Checklist)

> [!NOTE]
> Checklist này áp dụng chung cho mọi trang và tính năng trong dự án, tập trung vào nguyên tắc kiến trúc và tính module hóa.

### A. Tái Sử Dụng & Khử Trùng Lặp (Design System & Deduping)
- [ ] **Bảng & Thao tác**: Đã dùng `DataTable` và `TableActions` từ `components/common` thay vì viết `<table>` thô chưa?
- [ ] **Form & Toolbar**: Đã tái sử dụng `PageToolbar`, `FilterSelect`, `Button` thay vì thẻ HTML thô chưa?
- [ ] **Modal & Feedback**: Đã dùng `BaseModal` / `ConfirmModal` cho popup và `LoadingSpinner` / `EmptyState` cho feedback chưa?
- [ ] **Thông báo Toast**: Đã dùng `useToast()` từ `context/ToastContext` cho các thao tác thành công/thất bại chưa?
- [ ] **Khử trùng lặp (Deduping)**: Mỗi tính năng/tiện ích chỉ có một bản duy nhất, dùng chung giữa các page (không có hai modal, hai hàm, hai hook làm cùng một việc)?

### B. Kiến Trúc & Giới Hạn Dòng (Architecture & Size)
- [ ] **Kích thước file**: Page container < 200 dòng? Sub-component < 150 dòng? Hook < 120 dòng? Service/Mapper < 100 dòng?
- [ ] **Đúng thư mục**: File nằm đúng nơi (`constants/`, `hooks/`, `schemas/`, `services/`, `utils/<domain>/`, `components/<Feature>/`)? Tuyệt đối không tái tạo `features/` khi đã có `services/` và `utils/<domain>/`.
- [ ] **Single Responsibility**: Mỗi sub-component/file chỉ giải quyết 1 nhiệm vụ hiển thị/xử lý duy nhất?
- [ ] **Phân rã giao diện phức tạp**: Giao diện phức tạp (modal nhiều bước, sơ đồ/lưới, drawer chi tiết) đã tách thành các phần có tên rõ vai trò: vỏ (shell), từng phần con, và hook giữ logic/state chung?

### C. Phân Tách Cấu Trúc Dữ Liệu Form & Modal (Form & Modal Data Separation)
- [ ] **Đồng bộ Data Key chuẩn (Data Key Alignment)**: Key trường dữ liệu giữa Form State, Zod Schema, UI Fields và Entity đã nhất quán chưa (VD: cùng dùng `model`, không phân mảnh thành `modelName` ở form và `model` ở entity)?
- [ ] **Tách biệt Data Schema & Validation**: Toàn bộ logic kiểm tra hợp lệ dữ liệu (Zod Schema) nằm riêng trong `src/schemas/` chứ không viết inline trong Modal?
- [ ] **Tách biệt Form State & Mappers**: 
  - State khởi tạo (`INITIAL_FORM_STATE`) nằm tại `src/constants/<feature>Constants.js`?
  - Hàm biến đổi dữ liệu 2 chiều (`mapEntityToFormData`, `mapFormDataToEntity`) nằm tại `src/utils/<feature>/` (nhóm theo domain)?
  - Modal không tự ghép nối object payload/entity thủ công mà ủy quyền cho Mapper?
- [ ] **Không trộn lẫn Domain/Mock ngoài lề**: Modal không trực tiếp import mock data hoặc dữ liệu của domain khác mà để trống hoặc nhận qua props/API chuẩn?
- [ ] **Tách Combobox/Sub-inputs**: Các ô nhập có dropdown/search đã được tách thành sub-component độc lập?
- [ ] **Tách Form Fields nếu form dài**: Nếu form có từ 5-6 trường trở lên, đã tách khối FormFields riêng để giữ Modal đóng vai trò orchestrator điều phối submit/cancel?

### D. Hằng Số & Mapping (Constants & Enums)
- [ ] **Không hardcode chuỗi/màu**: Mọi class Tailwind động, badge colors, icon mappings, filter options đã được khai báo tập trung trong `src/constants/` chưa?
- [ ] **Zero Magic Numbers & Tiền Tệ Tập Trung**: 
  - Tuyệt đối KHÔNG viết số ma thuật hoặc rải rác các giá trị tiền tệ, hạn mức ví, gói nạp tiền thô (VD: `100000`, `250000`, `150000`) rải rác trong components hay pages.
  - Toàn bộ hằng số tài chính, số dư mặc định, ngưỡng cảnh báo, mệnh giá nạp nhanh và định dạng tiền tệ bắt buộc phải tập trung tại `src/constants/paymentConstants.js` hoặc file domain tương ứng và sử dụng hàm format chuẩn (`formatCurrencyVND`).
- [ ] **Khử trùng lặp Magic Strings / Fallback Labels**: Các chuỗi nhãn fallback lặp lại nhiều nơi (VD: `"Chưa có vị trí"`, `"Tự động phân bổ khi check-in"`) đã được định nghĩa thành constant dùng chung trong `constants/` thay vì viết chuỗi thô rải rác chưa?
- [ ] **Fallback an toàn**: Đã xử lý giá trị mặc định cho enum/loại dữ liệu chưa biết (VD: fallback về `"Vé lượt"` khi ticket rỗng)?

### E. Quản Lý State & Gọi API (Data Flow & React 19)
- [ ] **Custom Hook độc lập**: Logic `useEffect`, gọi API, hydration đa endpoint đã được tách sang `src/hooks/` chưa?
- [ ] **Cleanup & Race Condition**: Các effect gọi API có cờ `cancelled` hoặc `AbortController` để tránh race condition/memory leak khi unmount không?
- [ ] **Trạng thái đầy đủ**: Đã có đầy đủ xử lý cho 3 trạng thái: Loading (`isLoading`), Error (`backendError`), và Dữ liệu trống (`EmptyState`) chưa?
- [ ] **Optimistic UI / Reload handler**: Hook có cung cấp hàm `reload` hoặc refetch sau khi Create/Update/Delete thành công không?

### F. UX & Tương Tác Bảng (Interactive & Accessibility)
- [ ] **Dữ liệu nhạy cảm / PII**: Các trường như SĐT, CCCD, Biển số xe có format rõ ràng (font-mono), có fallback khi rỗng (`"—"`) và hỗ trợ tương tác phù hợp (`tel:`, copy)?
- [ ] **Stop Propagation**: Các nút hành động trong hàng bảng (Sửa, Xóa, Chi tiết) đã có `e.stopPropagation()` để không kích hoạt sự kiện chọn hàng (`onSelectRow`) chưa?

### G. Đường Dẫn Import & Verify Build (Imports & Verification)
- [ ] **Barrel File (`index.js`)**: Thư mục feature `components/<Feature>/` đã có `index.js` gom xuất khẩu các sub-component để Page import sạch gọn chưa?
- [ ] **Path Resolution an toàn**: Kiểm tra alias `@/` hoặc đường dẫn tương đối đúng tầng để tránh lỗi Rolldown bundler?
- [ ] **Build Verification**: Đã chạy `npm --prefix parking_management_frontend run build` và đạt mã thoát `0` (không có warning import chết, không lỗi cú pháp)?
- [ ] **Strict Backend Lock**: Đảm bảo 100% không chạm vào bất kỳ file nào trong `parking_management_backend/`.
