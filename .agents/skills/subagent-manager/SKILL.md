---
name: subagent-manager
description: >-
  Quản lý và kích hoạt nhanh các Subagents chuyên trách trong dự án (Frontend
  Refactor, Cross-Stack Verifier, Test Generator, UI/UX A11y Auditor) được cấu
  hình tại .agents/subagents/.
---
# Subagent Manager (`subagent-manager`)

Skill này giúp Agent tự động tra cứu, khởi tạo (`define_subagent`) và điều phối (`invoke_subagent`) các subagent chuyên trách đã được lưu trữ vĩnh viễn trong workspace dự án tại `.agents/subagents/`.

---

## 1. Bộ 4 Subagents Chuyên Trách Của Dự Án

| Tên Subagent | Đường dẫn cấu hình | Chế độ | Chức năng chính |
| :--- | :--- | :--- | :--- |
| **`frontend-refactor-specialist`** | `.agents/subagents/frontend-refactor-specialist/SUBAGENT.md` | Read/Write | Tái cấu trúc, bóc tách module < 200 dòng, đồng nhất `components/common`. |
| **`cross-stack-contract-verifier`** | `.agents/subagents/cross-stack-contract-verifier/SUBAGENT.md` | **Read-Only** | Đối soát hợp đồng API (Backend Serializer vs Frontend Service/Mapper) tránh lệch schema. |
| **`frontend-test-generator`** | `.agents/subagents/frontend-test-generator/SUBAGENT.md` | Read/Write | Tự động viết Vitest + React Testing Library cho UI components & hooks. |
| **`uiux-a11y-auditor`** | `.agents/subagents/uiux-a11y-auditor/SUBAGENT.md` | **Read-Only** | Audit độ tương phản màu, phím tắt keyboard, aria-labels và responsive. |

---

## 2. Quy trình điều phối tự động

Mỗi khi người dùng đưa ra yêu cầu thuộc phạm vi chuyên môn:
1. Agent đọc file `SUBAGENT.md` tương ứng trong `.agents/subagents/<name>/`.
2. Kiểm tra trạng thái đăng ký của subagent (gọi `define_subagent` nếu là phiên làm việc mới).
3. Gọi `invoke_subagent` kèm theo yêu cầu chi tiết. **LƯU Ý QUAN TRỌNG VỀ WORKSPACE**:
   - Đối với các subagent có quyền ghi/sửa code (`frontend-refactor-specialist`, `frontend-test-generator`): **BẮT BUỘC** truyền `Workspace: "share"` để cách ly thay đổi trên `git worktree` độc lập, giúp người dùng dễ dàng review hoặc revert thủ công hàng loạt mà không làm bẩn git working directory.
   - Đối với các subagent chỉ đọc (`cross-stack-contract-verifier`, `uiux-a11y-auditor`): Có thể dùng `Workspace: "inherit"`.
4. Nhận kết quả qua cơ chế Reactive Wakeup và báo cáo cho người dùng.
