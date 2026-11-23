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
- **Bảo toàn thiết kế và giao diện**: Khi sửa logic ở bất kỳ đâu, giữ nguyên cấu trúc layout, class names và nhãn gốc; không tự ý sáng tác thêm các thành phần phụ trợ chưa được yêu cầu.
- **Frontend-Specific Guardrails**: Chi tiết về React State (`useRef + useState`), vòng đời component và cấu trúc UI được định nghĩa độc lập tại `parking_management_frontend/AGENTS.md`.

## 4. Transparent Modification & Native Edit Guard
- **Bắt buộc dùng `edit_file` / `write_file`**: Mọi sửa đổi mã nguồn phải qua công cụ native để người dùng theo dõi Visual Diff trên IDE. Không tự ý dùng script (`python`, PowerShell) ghi đè file code nguồn trừ khi được người dùng yêu cầu rõ ràng.
- **Bảo toàn tuyệt đối UTF-8**: Mọi file chứa tiếng Việt có dấu phải giữ nguyên UTF-8, nghiêm cấm các thao tác gây lỗi font (mojibake).
- **Static Verification**: Sau khi sửa, chạy lint/build/test để kiểm tra cú pháp, imports và dependencies hợp lệ trước khi hoàn tất.

# Git Safety Guard Rules (Khóa Chặn Cứng Các Lệnh Nguy Hiểm Của Git)

> **Mục tiêu**: Ngăn chặn tuyệt đối mọi hành vi gây mất mã nguồn, ghi đè lịch sử hoặc làm hỏng repository Git của dự án (cả Frontend và Backend) do AI Agent hoặc thao tác dòng lệnh tự động thực thi.

---

## 1. Danh sách lệnh Git BỊ CẤM TUYỆT ĐỐI (Blacklist Lệnh Nguy Hiểm)

AI Agent hoặc bất kỳ script tự động nào KHÔNG ĐƯỢC PHÉP chạy các lệnh sau dưới bất kỳ hình thức nào:

### 🚫 Nhóm A: Hủy Diệt & Ghi Đè Lịch Sử (Force Push & Rewrite)
- `git push --force` hoặc `git push -f`
- `git push --force-with-lease` lên các nhánh chính (`main`, `master`, `production`, `release`, `staging`)
- `git filter-branch`, `git filter-repo`
- `git rebase -i` can thiệp các commit đã đẩy lên remote công khai

### 🚫 Nhóm B: Mất Mã Nguồn Chưa Lưu (Destructive Resets & Overwrite)
- `git reset --hard` (đặc biệt khi đang có uncommitted changes hoặc chưa tạo stash/backup)
- `git checkout -- .` hoặc `git restore .` mà không có sự xác nhận rõ ràng của người dùng
- `git clean -fdx` hoặc `git clean -fd` (xóa vĩnh viễn các file untracked, untracked configs, tài liệu mới)
- `git worktree remove --force` hoặc `git worktree remove -f` (nghiêm cấm ép xóa worktree có chứa thay đổi chưa commit; chỉ dùng `git worktree remove` an toàn)

### 🚫 Nhóm C: Xóa Nhánh Từ Xa & Xóa Nhánh Cứng (Destructive Deletion)
- `git push <remote> --delete <branch>` hoặc `git push <remote> :<branch>`
- `git branch -D` (xóa cứng nhánh chưa được merge mà chưa hỏi ý kiến)

### 🚫 Nhóm D: Dọn Sạch Bộ Nhớ Khôi Phục (Reflog Purging)
- `git reflog expire --expire=now --all`
- `git prune`
- `git gc --prune=now`

---

## 2. Quy Trình Thay Thế An Toàn Khi Cần Thao Tác (Safe Alternatives)

1. **Khi cần hủy thay đổi cục bộ (Discard changes)**:
   - Ưu tiên lưu tạm vào stash trước: `git stash push -u -m "backup-before-discard"`
   - Tuyệt đối không dùng `git reset --hard` ngay lập tức.
2. **Khi cần quay lại commit cũ**:
   - Dùng `git revert <commit-hash>` (tạo commit đảo ngược an toàn, giữ nguyên lịch sử) thay vì `git reset --hard`.
3. **Khi cần dọn file rác / file sinh ra ngoài ý muốn**:
   - Kiểm tra kỹ bằng `git status -s` hoặc `git clean -n` (dry-run mode) trước khi xóa.
4. **Khi cần đẩy code (Push)**:
   - Chỉ dùng `git push origin <tên-nhánh>` thông thường (fast-forward).
   - Nếu gặp conflict, BẮT BUỘC thực hiện `git pull --rebase` hoặc `git merge` và giải quyết conflict, không bao giờ dùng `--force`.
5. **Bảo vệ nhánh chính**:
   - Không commit trực tiếp lên `main` hoặc `master`. Luôn làm việc trên nhánh tính năng (`feat/*`, `fix/*`).

# Parking Management Workspace Router

Monorepo root for Smart Mobility Parking Lot Management System (`Bãi xe Smart Mobility`).
Contains two independent sub-projects:
- `parking_management_backend/`: Django 6.1.2 + PostgreSQL 18.6 REST API service.
- `parking_management_frontend/`: React 19 + Vite web client.

---

## 1. Operating Principles & Safety Guardrails

1. **Disciplined Coding & Surgical Changes**:
   - **Surgical Edits**: Touch only what you must. Do not refactor adjacent code or reformat styling unless requested.
   - **Simplicity First**: Implement the minimal code that cleanly solves the problem.
   - **Goal-Driven & Verification**: Every change must be verified (lint, build, or tests). Refer to skill `disciplined-coding-workflow`.

2. **Project Integrity & Guardrails**:
   - **STRICT BACKEND CODE LOCK**: Backend do team khác phụ trách. Tuyệt đối KHÔNG sửa đổi, thêm mới, xóa hay can thiệp bất kỳ file nào trong `parking_management_backend/`. Chỉ đọc tài liệu/specs (`docs/`, `db/`) để mapping API lên Frontend khi cần.
   - **STRICT ENV PRIVACY LOCK**: NEVER inspect, read, display, or tool-read real `.env` secret files (`.env`, `.env.local`, `.env.production`). Only `.env.example` templates are permitted.
   - **STRICT GIT SAFETY GUARD**: Absolute ban on destructive git commands (`git push --force`, `git reset --hard`, `git clean -fdx`, `git checkout .`, `git push --delete`, `git branch -D`, `git prune/gc`). Follow `.rulesync/rules/git-safety-guard.md`.
   - **SUBAGENT ISOLATION GUARD & MANDATORY VERIFICATION GATE**: BẮT BUỘC khi khởi chạy bất kỳ subagent nào có quyền ghi/sửa code (`EnableWriteTools: true` hoặc worker sửa code trong swarm), luôn luôn phải thiết lập `Workspace: "branch"` hoặc `Workspace: "share"`. Tuyệt đối NGHIÊM CẤM dùng `Workspace: "inherit"` khi sửa code. **BẮT BUỘC CHỨNG MINH BẰNG LỆNH (CẤM NÓI SUÔNG)**: Ngay sau khi khởi chạy subagent ở mode `branch`/`share`, Agent BẮT BUỘC phải chạy ngay lệnh `git worktree list` và xuất trực tiếp output thực tế ra cho người dùng thấy rõ: (1) Role & Nhiệm vụ, (2) Chế độ `Workspace: "branch"` (hoặc `"share"`), (3) Bằng chứng từ output lệnh `git worktree list` kèm đường dẫn worktree thực tế trên ổ cứng để người dùng tự kiểm tra và revert thủ công bất cứ lúc nào.

3. **Context & Token Optimization**:
   - **Targeted Reads Only**: Avoid recursive scans (`Get-ChildItem -Recurse`, `tree`) or mass reads (> 250 lines). Use targeted line ranges or `Select-String`.
   - **Architecture & Cross-Project Resolution**: Use `codebase-graph-query` skill or `graphify-out/graph.json` (`graphify query ...`) instead of opening multiple files across projects.
   - **Frontend Modular Standards**: Follow `.rulesync/skills/frontend-modular-clean-code` for React components (< 200 lines, custom hooks < 120 lines, shared components from `components/common/`).

---

## 2. On-Demand Documentation Index

When deep domain context is required, read target files directly:

- **Run & Setup**: `02-run-backend-and-frontend.md`, `docker-compose.yml`, `Taskfile.yml`
- **Backend Specs & APIs** (`parking_management_backend/`):
  - API Catalog: `docs/api-endpoints.md`, `docs/guides/01-frontend-api-guide.md`
  - SRS & Decisions: `docs/requirements/06-frontend-srs-db-alignment.md` (TL-01 to TL-49), `07-fe-srs-traceability.md`, `03-delete-rules-catalog.md`
  - DB Schema: `db/01-schema.sql` (PostgreSQL 18.6 schema)
- **Frontend Specs & Design** (`parking_management_frontend/`):
  - Architecture & SRS: `docs/01-architecture.md`, `docs/02-srs.md`, `docs/03-business-flows.md`
  - Coding & Tests: `docs/04-coding-convention.md`, `docs/05-testing.md`
  - Design Tokens: `docs/design-system/`

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- For codebase or architecture questions, when `graphify-out/graph.json` exists, first run `graphify query "<question>"` (CLI) or `query_graph` (MCP, always pass `project_path: "E:/code/parking_management"` to ensure the correct workspace graph is resolved). Use `graphify path "<A>" "<B>"` / `shortest_path` for relationships and `graphify explain "<concept>"` / `get_node` for focused concepts. These return a scoped subgraph, usually much smaller than `GRAPH_REPORT.md` or raw grep output.
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
