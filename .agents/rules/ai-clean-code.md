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

## 5. Subagent Isolation Guard & Mandatory Verification Gate
- **Cấm tuyệt đối `Workspace: "inherit"` khi sửa code**: Mọi subagent hoặc worker có quyền ghi/sửa code (`EnableWriteTools: true`) BẮT BUỘC phải chạy trên `Workspace: "branch"` hoặc `Workspace: "share"`. Chế độ `inherit` chỉ được phép dùng cho tác vụ đọc/nghiên cứu thuần túy (read-only).
- **Bắt buộc chứng minh bằng lệnh thực tế (Proof via Command - Cấm chỉ nói suông)**: 
  - Ngay sau khi khởi chạy subagent ở mode `branch` hoặc `share`, Agent **BẮT BUỘC** phải tự động chạy lệnh terminal `git worktree list`.
  - Phải trích xuất và hiển thị output thực tế của lệnh đó trong câu trả lời cho người dùng để chứng minh sự tồn tại của nhánh cách ly.
  - Phải in rõ ràng:
    1. Role và nhiệm vụ của subagent.
    2. Mode: `Workspace: "branch"` (hoặc `"share"`).
    3. Output nguyên bản từ lệnh `git worktree list` kèm đường dẫn worktree thực tế trên ổ đĩa để người dùng giám sát và có thể tự revert thủ công bất cứ lúc nào.


