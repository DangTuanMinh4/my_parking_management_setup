---
name: spec-driven-development
description: Quy trình triển khai tính năng theo mô hình Spec-Driven Development (Spec-Kit SDD) cho Frontend, từ Spec -> Plan -> Tasks -> Verification, tuân thủ nghiêm ngặt AI Clean Code và kiến trúc module hóa.
targets: ["*"]
---

# Spec-Driven Development (SDD) Workflow Skill

Sử dụng skill này khi người dùng yêu cầu tạo mới hoặc tái cấu trúc một tính năng/màn hình trên Frontend (`parking_management_frontend`).

## Quy trình thực hiện

### Bước 1: Khởi tạo Thư mục Spec
Khi bắt đầu một feature mới có tên `<feature-name>`:
1. Tạo thư mục `parking_management_frontend/docs/specs/<feature-name>/`.
2. Tạo 3 file hạt nhân dựa trên template tại `parking_management_frontend/docs/specs/_template/`:
   - `spec.md`: Định nghĩa User Story, API Contract từ backend docs (`parking_management_backend/docs/`), Acceptance Criteria.
   - `plan.md`: Thiết kế module hóa component (< 200 dòng/file), cô lập hook `use[Feature]Logic`, chiến lược chống double-click (`useRef` + `useState`).
   - `tasks.md`: Danh sách công việc phân rã tuần tự theo 4 giai đoạn.

### Bước 2: Thẩm định Contract (Zero Assumption)
- Kiểm tra hợp đồng API với `parking_management_backend/docs/api-endpoints.md` hoặc `06-frontend-srs-db-alignment.md`.
- Tuyệt đối không tự suy đoán field dữ liệu.
- Kích hoạt subagent `cross-stack-contract-verifier` nếu có chênh lệch giữa DTO backend và UI Model frontend.

### Bước 3: Thực thi Tuần tự qua `tasks.md`
Agent chỉ thực thi lần lượt từng mục trong `tasks.md`:
1. **Types & Constants**: Khai báo type và hằng số UPPER_SNAKE_CASE (Zero Magic Numbers).
2. **Mapper**: Bóc tách sub-domain (Single Source of Truth), chống shadowing dữ liệu.
3. **Custom Hook**: Quản lý state, API call, timer cleanup và dual-layer double-click guard.
4. **Components**: Chia nhỏ UI < 200 dòng, không render raw object vào JSX.

### Bước 4: Verification & Graph Sync
- Chạy test kiểm thử qua `pnpm run test` hoặc `pnpm run lint`.
- Chạy cập nhật đồ thị kiến trúc: `graphify update .`.
