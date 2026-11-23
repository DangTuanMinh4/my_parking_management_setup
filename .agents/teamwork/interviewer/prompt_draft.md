Tích hợp scan biển số xe từ hình ảnh và luồng quét camera với việc tự động hiển thị thông tin xe đã có trong hệ thống, kiểm tra tính năng tự động điền biển số xe, và hoàn thiện hiển thị lịch sử đối soát / lịch sử ra vào bãi trên giao diện Frontend.

Working directory: parking_management_frontend
Integrity mode: development

## Requirements

### R1. Tích hợp scan biển số xe từ hình ảnh và hoàn thiện thông tin hiển thị
- Bổ sung chức năng scan biển số xe từ file hình ảnh bên cạnh luồng quét từ camera (tại `ScanPlateModal.jsx` và các component quét camera liên quan trong `VehicleManagement`).
- Đảm bảo hiển thị đầy đủ thông tin cho cả hai luồng scan biển số xe (từ ảnh và từ camera) khi có thông tin còn thiếu.
- Khi biển số nhận diện khớp với xe đã tồn tại trong hệ thống, tự động hiển thị các thông tin: Tên xe, Hãng xe, Tên khách hàng, Số điện thoại, Vị trí đỗ.
- Dữ liệu thông tin xe được truy vấn qua API/service frontend có sẵn hoặc danh sách xe hiện có trong client store.

### R2. Kiểm tra và bảo toàn tính năng tự động điền/paste biển số xe
- Kiểm tra và đảm bảo mã nguồn tự động paste / điền số biển số xe vào ô tìm kiếm hoặc trường nhập liệu sau khi tra cứu/nhận diện vẫn hoạt động bình thường, không bị xóa hoặc làm mất tính năng.
- Không thực hiện tính năng "Tìm xe" (đã có thành viên khác đảm nhiệm).

### R3. Hiển thị lịch sử đối soát / lịch sử ra vào bãi sau khi quét camera
- Kiểm tra trước từ nhánh `minh` (bằng các lệnh kiểm tra an toàn, không checkout nhánh làm ảnh hưởng workspace) xem tính năng hiển thị lịch sử đối soát đã được xử lý chưa để kế thừa hoặc đối chiếu.
- Đảm bảo trang hiển thị được lịch sử đối soát / lịch sử ra vào bãi cần có sau khi quét camera trên giao diện Frontend.

### R4. Ràng buộc an toàn dự án (Frontend lock & Strict Git Safety)
- STRICT BACKEND LOCK: Chỉ thực hiện trên Frontend (`parking_management_frontend/`), nghiêm cấm sửa đổi mã nguồn hoặc các file thuộc Backend (`parking_management_backend/`).
- STRICT GIT SAFETY: Nghiêm cấm tuyệt đối việc chạy các lệnh git mang tính phá hủy hoặc làm mất mã nguồn như `git checkout`, `git reset --hard`, `git restore`. Mọi thay đổi chưa commit trên workspace phải được bảo toàn tuyệt đối. Mọi thao tác kiểm tra nhánh khác chỉ được dùng các lệnh an toàn (như `git log`, `git show`, `git diff`).

## Acceptance Criteria

### License Plate Scan & Auto-fill
- [ ] Chức năng scan biển số xe từ hình ảnh hoạt động trên giao diện (ví dụ tải ảnh và trích xuất/xử lý biển số).
- [ ] Luồng scan camera và scan ảnh hiển thị đồng bộ và đầy đủ các trường thông tin.
- [ ] Khi biển số nhận diện trùng khớp xe trong hệ thống, giao diện tự động điền/hiển thị chính xác: Tên xe, Hãng xe, Tên khách hàng, Số điện thoại, Vị trí đỗ.
- [ ] Tính năng tự động paste biển số xe vào ô tra cứu/nhập liệu được bảo toàn và hoạt động chính xác.
- [ ] Phần "Tìm xe" không bị can thiệp hay sửa đổi ngoài phạm vi.

### History Display & Branch Check
- [ ] Nhánh `minh` được kiểm tra an toàn (không dùng `git checkout`, `git reset`, `git restore`) để xác định trạng thái xử lý lịch sử đối soát.
- [ ] Trang hiển thị lịch sử đối soát / lịch sử ra vào bãi sau khi quét camera được hiển thị đầy đủ và hoạt động được trên Frontend.

### Project & Safety Compliance
- [ ] Không có file nào trong thư mục `parking_management_backend/` bị thay đổi.
- [ ] Không có lệnh git nguy hiểm nào (`git checkout`, `git reset --hard`, `git restore`) được thực thi trong suốt quá trình.
- [ ] Ứng dụng Frontend build và chạy không phát sinh lỗi cú pháp hay runtime crash liên quan đến các tính năng trên.
