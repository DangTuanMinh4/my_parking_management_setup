# Smart Mobility Parking Lot Management System (Monorepo)

Hệ thống Quản lý Bãi đỗ xe Thông minh Smart Mobility — Monorepo quản lý toàn bộ hạ tầng dịch vụ Backend (Django REST Framework), Web Client Frontend (React 19 + Vite), bộ quy chuẩn AI Clean Code, Git Guardrails và hệ thống Telemetry giám sát tự động.

---

## ⚠️ Lưu Ý Quan Trọng Về Mã Nguồn (Repository Note)

> [!IMPORTANT]
> **Repository này (`my_parking_management_setup`) KHÔNG chứa mã nguồn của Backend và Frontend.**
> - Hai thư mục `parking_management_backend/` và `parking_management_frontend/` là **hai Git sub-repositories độc lập** do các nhóm phát triển quản lý riêng biệt và đã được thiết lập bỏ qua trong `.gitignore`.
> - Repo này đóng vai trò là **Workspace Setup & Orchestration Hub**: chịu trách nhiệm điều phối môi trường chạy (Docker, Taskfile, local scripts), quản lý tài liệu kiến trúc, bộ quy tắc an toàn mã nguồn (**AI Clean Code & Git Safety Guardrails**) cùng hệ thống Telemetry giám sát.
> - Khi clone repository này về, bạn cần clone riêng mã nguồn Backend và Frontend vào 2 thư mục tương ứng theo hướng dẫn tại [02-run-backend-and-frontend.md](02-run-backend-and-frontend.md).
> - **Tìm kiếm mã nguồn trên VS Code**: Hệ thống đã cấu hình sẵn `.ignore` và `.vscode/settings.json` để cho phép tìm kiếm (`Ctrl + Shift + F`) trực tiếp trong 2 thư mục `parking_management_backend/` và `parking_management_frontend/` mà không ảnh hưởng tới trạng thái bỏ qua trong `.gitignore` hay các thư mục tạm khác.

---

## 🏗️ Cấu Trúc Dự Án (Project Structure)

```text
parking_management/
├── parking_management_backend/   # Django 6.1.2 + PostgreSQL 18 REST API Service
├── parking_management_frontend/  # React 19 + Vite + Tailwind CSS Web Client
├── .agents/                      # AI Subagents, Rules, Hooks & Telemetry Monitor
│   ├── rules/                    # Quy tắc AI Clean Code & Git Safety Guard
│   ├── scripts/                  # Hooks bảo vệ Git và Telemetry
│   ├── server/                   # Lightweight Telemetry Server
│   └── game_ui/                  # Real-time Subagent Dashboard UI
├── Taskfile.yml                  # Task runner tự động hóa quy trình phát triển
├── docker-compose.yml            # Docker Compose triển khai toàn bộ Full-Stack
├── 02-run-backend-and-frontend.md # Hướng dẫn chạy thủ công & chi tiết cấu hình
├── start-dev.bat / .ps1          # Script 1-click khởi chạy môi trường local
└── README.md                     # Tài liệu tổng quan dự án
```

---

## 🚀 Khởi Động Nhanh (Quick Start)

### 1. Yêu Cầu Môi Trường (Prerequisites)
- **Node.js**: v22+
- **Python**: v3.12+ (hoặc Docker)
- **Docker Desktop**: Khuyến nghị dùng để chạy cơ sở dữ liệu PostgreSQL và Backend
- **Task**: (Tùy chọn) Xem tại [taskfile.dev](https://taskfile.dev)

---

### 2. Khởi Động 1-Click (Khuyến nghị trên Windows)

Chạy file script tích hợp sẵn tại root:
```cmd
start-dev.bat
```
Script sẽ tự động khởi động Backend và Frontend lên các cổng tương ứng.

---

### 3. Sử Dụng Taskfile (Khuyến nghị cho Developer)

```bash
# 1. Khởi động Database & Backend
task dev

# 2. Khởi động Frontend Web Client (terminal riêng)
task frontend:dev

# 3. Kiểm tra trạng thái các dịch vụ
task status

# 4. Tắt toàn bộ dịch vụ
task down
```

---

### 4. Sử Dụng Docker Compose (Full Stack)

```bash
# Tạo file môi trường từ template
cp .env.example .env

# Khởi chạy toàn bộ hệ thống
docker compose up -d

# Xem log thời gian thực
docker compose logs -f

# Tắt hệ thống
docker compose down
```

---

## 🌐 Danh Sách Endpoint & Dịch Vụ (Service URLs)

| Dịch Vụ | Địa Chỉ Local | Mô Tả |
| :--- | :--- | :--- |
| **Frontend Web** | [http://127.0.0.1:5173](http://127.0.0.1:5173) | Cổng vận hành, Quản trị bãi xe & Khách hàng |
| **Backend API** | [http://127.0.0.1:8000](http://127.0.0.1:8000) | REST API Gateway |
| **API Health Check** | [http://127.0.0.1:8000/api/health/](http://127.0.0.1:8000/api/health/) | Trạng thái sẵn sàng của Backend |
| **Swagger UI** | [http://127.0.0.1:8000/api/docs/](http://127.0.0.1:8000/api/docs/) | Tài liệu API tương tác trực quan |
| **OpenAPI Schema** | [http://127.0.0.1:8000/api/schema/](http://127.0.0.1:8000/api/schema/) | JSON Schema OpenAPI 3.0 |

---

## 👤 Tài Khoản Mặc Định Môi Trường Dev (Test Credentials)

- **Email**: `hoang.dinh.khang@example.com`
- **Thiết lập mật khẩu**:
  ```bash
  task dev:set-password -- PW=testpass123
  ```

---

## 🛡️ Bộ Quy Chuẩn Kỹ Thuật & An Toàn (Core Guardrails)

Dự án áp dụng bộ quy chuẩn nghiêm ngặt được thực thi tự động qua Git Hooks:
- **Git Safety Guard**: Khóa cứng hoàn toàn các thao tác nguy hiểm (`git push --force`, `git reset --hard`, `git clean -fd`, `git worktree remove -f`).
- **Subagent Isolation Guard**: Bắt buộc các tác vụ tự động/sửa code phải chạy trên worktree cách ly (`branch`/`share`).
- **Financial Safety Guard**: Mọi giao dịch nạp tiền/số dư chưa có API thật phải ghi chú rõ là chế độ mô phỏng (Sandbox).
