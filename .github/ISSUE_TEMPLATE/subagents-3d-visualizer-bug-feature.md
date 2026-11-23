# [FEATURE/BUG] Nâng cấp và hoàn thiện Visualizer cho Subagents (2D/3D Canvas)

## 📌 1. Tóm tắt vấn đề (Overview)
Tính năng hiển thị trực quan tiến trình hoạt động của AI Subagents hiện tại (trong `.agents/game_ui/index.html` và `.agents/server/subagent_game_server.py`) mới chỉ dừng ở mức prototype 2D Canvas đơn giản, còn tồn tại nhiều điểm chưa hoàn thiện, thiếu sót kỹ thuật và chưa đạt chuẩn không gian 3D trực quan như kỳ vọng.

---

## 🔍 2. Các sai sót và điểm hạn chế hiện tại (Current Issues & Limitations)

### A. Về giao diện và không gian hiển thị (Visual & Canvas)
- [ ] **Chưa hỗ trợ không gian 3D**: Hiện tại Canvas đang render 2D tĩnh bằng HTML5 Canvas 2D Context, chưa tích hợp WebGL / Three.js / Babylon.js để hiển thị mô hình 3D tương tác.
- [ ] **Thiếu hoạt ảnh động (Animations & Transitions)**: Các agent di chuyển và tương tác chưa mượt mà, thiếu chuyển động trạng thái (Idle -> Working -> Success/Fail).
- [ ] **Chưa có camera tương tác**: Chưa có OrbitControls để xoay, zoom, pan camera quan sát toàn cảnh workspace làm việc của các subagents.

### B. Về đồng bộ dữ liệu thời gian thực (Telemetry & Sync)
- [ ] **Polling thay vì WebSocket hai chiều**: Frontend hiện đang định kỳ fetch polling HTTP từ server (`events.json`), dễ dẫn đến độ trễ hoặc nghẽn tài nguyên. Cần chuyển sang WebSocket song công.
- [ ] **Bỏ lỡ sự kiện vòng đời (Lifecycle Tracking)**: Chưa bắt trọn vẹn toàn bộ các event `PreToolUse`, `PostToolUse`, và `SubagentTerminated` khi subagent chạy ngầm hoặc bị hủy.
- [ ] **Chưa hiển thị chi tiết Worktree/Branch**: Giao diện chưa thể hiện trực quan đường dẫn worktree cách ly (`Workspace: branch/share`) và commit SHA thực tế của từng subagent.

### C. Về trải nghiệm người dùng & Âm thanh (UX & Audio)
- [ ] **Hệ thống Audio/SFX**: Âm thanh Web Audio API hiện tại chỉ là các tiếng bip tần số cố định, chưa có hiệu ứng âm thanh chuyên nghiệp hoặc cơ chế tắt âm ghi nhớ local storage.
- [ ] **Responsive & Đa màn hình**: Giao diện cố định tỷ lệ, khi co giãn trên màn hình nhỏ hoặc split view trong IDE dễ bị vỡ bố cục.

---

## 🎯 3. Đề xuất giải pháp & Lộ trình thực hiện (Proposed Enhancements)

1. **Giai đoạn 1: Nâng cấp Three.js / WebGL 3D Scene**:
   - Tích hợp Three.js để dựng một không gian phòng điều khiển 3D (Subagent Cyber Command Center).
   - Render mỗi subagent thành một avatar/bot 3D với màu sắc nhận diện theo vai trò (Refactor, Verifier, Tester, Auditor).
2. **Giai đoạn 2: Tối ưu WebSocket Server**:
   - Nâng cấp `subagent_game_server.py` sử dụng `websockets` hoặc FastAPI WebSocket để stream event tức thì từ hook PowerShell.
3. **Giai đoạn 3: Tích hợp Worktree HUD Inspector**:
   - Click vào bất kỳ subagent 3D nào sẽ mở popover xem realtime:
     - Tên Agent & Nhiệm vụ
     - Nhánh Git & Đường dẫn Worktree
     - Lịch sử lệnh & Tool calls đang thực thi.

---

## 📎 Tài liệu liên quan
- `.agents/game_ui/index.html`
- `.agents/server/subagent_game_server.py`
- `.agents/scripts/subagent-telemetry-hook.ps1`
- `start_game_monitor.bat`
