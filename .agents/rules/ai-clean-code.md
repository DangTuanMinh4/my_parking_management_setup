---
trigger: always_on
---
# AI Clean Code & Core Guardrails

Quy tắc bắt buộc áp dụng khi viết, sửa đổi và review code trong workspace:

## 1. Zero Magic Numbers & Data Integrity
- **Không số/chuỗi ma thuật**: ID cổng, timeout, tỷ lệ, mã trạng thái... phải là hằng số `UPPER_SNAKE_CASE` trong constants hoặc đầu file.
- **Chính trực dữ liệu**: Tuyệt đối không bịa dữ liệu giả lập, điểm số AI (`aiConfidence`), trạng thái vé, giá tiền hoặc phí gửi xe nếu không có dữ liệu thực tế từ backend hoặc tài liệu yêu cầu.
- **Minh bạch tài chính & Khóa an toàn mô phỏng (Financial Safety Guardrail)**: 
  - Mọi trường thông tin liên quan đến tiền, số dư ví, nạp tiền chưa có backend thật BẮT BUỘC phải ghi chú rõ ràng là "Mô phỏng" (Simulation / Sandbox).
  - Nghiêm cấm thể hiện như một giao dịch tài chính đã thực thi thành công vào tài khoản ngân hàng thật khi backend chưa có API xác nhận có chữ ký bảo mật.

## 2. Async & Resource Hygiene
- **Cleanup Timers & Subscriptions**: Mọi timer, interval, socket, tiến trình nền phải được dọn dẹp giải phóng tài nguyên khi kết thúc hoặc unmount.
- **Error Handling**: Không để chuỗi thông báo lỗi dài/phức tạp lồng ghép trong logic nghiệp vụ. Tách thành pure helper functions hoặc error mappers riêng.

## 3. Surgical Edits & Scope Discipline
- **Sửa đúng phạm vi (Surgical Edit)**: Chỉ can thiệp đúng logic cần sửa để giải quyết mục tiêu, không tự ý refactor lan truyền sang các phần mã nguồn xung quanh.
- **Bảo toàn thiết kế và giao diện**: Khi sửa logic, giữ nguyên cấu trúc layout, class names và nhãn gốc; không tự ý sáng tác thêm các thành phần phụ trợ chưa được yêu cầu.
- **Frontend-Specific Guardrails**: Chi tiết về React State (`useRef + useState`), vòng đời component và cấu trúc UI được định nghĩa độc lập tại `parking_management_frontend/AGENTS.md`.

## 4. Transparent Modification & Native Edit Guard
- **Bắt buộc dùng `edit_file` / `write_file`**: Mọi sửa đổi mã nguồn phải qua công cụ native để người dùng theo dõi Visual Diff trên IDE. Không tự ý dùng script (`python`, PowerShell) ghi đè file code nguồn trừ khi được người dùng yêu cầu rõ ràng.
- **Bảo toàn tuyệt đối UTF-8**: Mọi file chứa tiếng Việt có dấu phải giữ nguyên UTF-8, nghiêm cấm các thao tác gây lỗi font (mojibake).
- **Static Verification**: Sau khi sửa, chạy lint/build/test để kiểm tra cú pháp, imports và dependencies hợp lệ trước khi hoàn tất.
