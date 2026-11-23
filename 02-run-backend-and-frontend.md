# Chạy Backend và Frontend trên máy local

Tài liệu này hướng dẫn chạy đồng thời:

- Backend Django REST API tại `http://127.0.0.1:8000`
- Frontend Vite React tại `http://127.0.0.1:5173`
- PostgreSQL 18.6 bằng Docker Compose

## 1. Điều kiện cần

- Windows PowerShell
- Docker Desktop đang chạy
- Python 3.14.x theo yêu cầu project
- Node.js và npm

Mở hai cửa sổ PowerShell riêng biệt:

```powershell
cd E:\code\parking_management\parking_management_backend
```

```powershell
cd E:\code\parking_management\parking_management_frontend
```

## 2. Cài dependency backend

Chỉ cần thực hiện khi tạo virtualenv mới hoặc dependency thay đổi:

```powershell
cd E:\code\parking_management\parking_management_backend
\.venv\Scripts\python.exe -m pip install -r requirements\02-dev.txt
```

`02-dev.txt` đã bao gồm `01-base.txt`, Django, DRF, PostgreSQL driver, OCR runtime và các công cụ test/lint.

## 3. Khởi động PostgreSQL và backend

### 3.1. Khởi động database

```powershell
cd E:\code\parking_management\parking_management_backend
docker compose up -d db
docker compose ps
```

Database được bind tại `127.0.0.1:5433` theo cấu hình local hiện tại.

### 3.2. Khởi động backend bằng Docker Compose

```powershell
docker compose up -d web
docker compose ps
```

Kiểm tra backend:

```powershell
curl.exe http://127.0.0.1:8000/api/health/
```

Kết quả mong đợi:

```json
{"status":"healthy","database":"connected","ocr_ready":true}
```

Swagger UI:

```text
http://127.0.0.1:8000/api/docs/
```

OpenAPI schema:

```text
http://127.0.0.1:8000/api/schema/
```

### 3.3. Chạy Django trực tiếp bằng virtualenv (tùy chọn)

Nếu không dùng service `web` trong Docker, có thể chạy:

```powershell
cd E:\code\parking_management\parking_management_backend
\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

Database vẫn phải được khởi động bằng `docker compose up -d db`.

## 4. Tạo password development

Dữ liệu seed không có password sử dụng được. Tự chọn một password local và truyền qua biến môi trường, không ghi password vào repository:

```powershell
$env:ACCOUNT_PASSWORD = "<your-local-development-password>"
docker compose exec -e ACCOUNT_PASSWORD web python manage.py set_account_password --identifier hoang.dinh.khang@example.com
Remove-Item Env:ACCOUNT_PASSWORD
```

Sau đó dùng email `hoang.dinh.khang@example.com` và password local vừa chọn để đăng nhập frontend. Không sử dụng password development cho staging hoặc production.

## 5. Khởi động frontend

```powershell
cd E:\code\parking_management\parking_management_frontend
npm install
npm run dev -- --host 127.0.0.1
```

Mở:

```text
http://127.0.0.1:5173/
```

Vite proxy tự chuyển các request `/api/*` sang backend `http://127.0.0.1:8000`.

## 6. Kiểm tra dữ liệu backend trên trang Quản lý xe

1. Mở `http://127.0.0.1:5173/login`.
2. Đăng nhập bằng tài khoản development và password local ở trên.
3. Mở `http://127.0.0.1:5173/vehicles`.
4. Nhập `43K` vào ô tìm kiếm.
5. Trang phải hiển thị nhãn `Đang dùng dữ liệu backend` và các xe từ PostgreSQL.

Nếu chưa đăng nhập hoặc session hết hạn, trang giữ mockdata và hiển thị cảnh báo fallback. Mockdata không bị xóa.

## 7. Kiểm tra build frontend

```powershell
cd E:\code\parking_management\parking_management_frontend
npm run build
```

## 8. Dừng chương trình

Dừng frontend bằng `Ctrl+C` trong cửa sổ đang chạy Vite.

Dừng backend và database:

```powershell
cd E:\code\parking_management\parking_management_backend
docker compose stop web db
```

Lệnh `docker compose stop` giữ nguyên dữ liệu database. Không dùng `docker compose down -v` nếu không muốn xóa volume PostgreSQL.

## 9. Xử lý lỗi thường gặp

### `401 Unauthorized` khi tìm xe

Đăng nhập qua `/login` bằng tài khoản backend. Frontend phải tạo Django session trước khi gọi vehicle-search.

### Docker không kết nối được

Mở Docker Desktop, chờ engine khởi động, sau đó chạy lại:

```powershell
docker compose up -d db web
docker compose ps
```

### Port đã được sử dụng

Kiểm tra process đang dùng port `8000`, `5433` hoặc `5173`, rồi dừng process đó hoặc đổi port trong cấu hình local.

### Frontend hiển thị mockdata

Kiểm tra backend health, đăng nhập lại, rồi mở DevTools Network để xác nhận request `/api/v1/parking/vehicle-search/` trả HTTP `200`.
