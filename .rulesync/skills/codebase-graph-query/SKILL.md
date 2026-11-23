---
name: codebase-graph-query
description: "Tra cứu quan hệ kiến trúc, dependencies, call-graph và luồng xử lý đa file qua Knowledge Graph local (Graphify) cho cả Frontend và Backend để tiết kiệm token và định vị chính xác vị trí code trước khi đọc source."
targets: ["*"]
---

# Workflow: Codebase Knowledge Graph Traversal (`codebase-graph-query`)

Sử dụng skill này khi cần tìm hiểu kiến trúc, luồng dữ liệu hoặc quan hệ giữa nhiều files (cả Frontend và Backend) thay vì mở/đọc hàng loạt files gây tốn token và loãng context.

---

## 1. Khi nào nên dùng
- **Câu hỏi kiến trúc / luồng dữ liệu**: Khi cần biết component X ở FE gọi API/Model nào ở Backend.
- **Trước khi refactor hoặc sửa code**: Cần xác định phạm vi ảnh hưởng (blast radius) của một hàm hoặc component trên toàn hệ thống.
- **Tìm đường đi kết nối (Path)**: Tìm xem File/Symbol A liên kết tới File/Symbol B qua những mắt xích nào.

---

## 2. Các lệnh tra cứu Graphify CLI (Chạy từ thư mục gốc `E:\code\parking_management`)

Đồ thị chung của cả dự án nằm tại: `graphify-out/graph.json`.

### Tra cứu qua MCP Tool (`query_graph`)
Khi gọi qua MCP `query_graph`, luôn đính kèm tham số `project_path`:
```json
{
  "question": "<câu hỏi hoặc từ khóa>",
  "project_path": "E:/code/parking_management"
}
```

### A. Truy vấn ngữ nghĩa / thực thể (`query`)
Tìm các node và liên kết liên quan tới câu hỏi hoặc từ khóa:
```powershell
graphify query "<từ khóa>" --graph graphify-out/graph.json --budget 1500
```
*Tùy chọn hữu ích*:
- `--budget 1500`: Giới hạn token output ngắn gọn, không spam context.
- `--dfs`: Đi sâu theo chuỗi liên kết (depth-first) thay vì tỏa rộng (breadth-first).

### B. Tìm đường liên kết giữa 2 files / symbols (`path`)
Xác định chuỗi imports, calls kết nối giữa 2 vị trí:
```powershell
graphify path "<SymbolA hoặc FileA>" "<SymbolB hoặc FileB>" --graph graphify-out/graph.json --undirected
```

### C. Giải thích chi tiết 1 component / file (`explain`)
Xem toàn bộ inbound & outbound dependencies của 1 node cụ thể:
```powershell
graphify explain "<TênFile hoặc Component>" --graph graphify-out/graph.json
```

### D. Cập nhật lại đồ thị khi có thay đổi code lớn (`update`)
Khi có nhiều file mới được thêm vào hoặc refactor lớn:
```powershell
graphify update . --no-cluster
```

---

## 3. Quy trình thực hiện (Token-efficient Workflow)

```text
[Nhận yêu cầu kiến trúc / đa file]
           │
           ▼
1. Chạy `graphify query` hoặc `graphify explain` để xác định đúng files liên quan
           │
           ▼
2. Có đủ thông tin liên kết?
   ├── CÓ  --> Chỉ đọc chính xác 1-2 file cần can thiệp (surgical read)
   └── KHÔNG -> Đọc thêm file lân cận để xác minh
           │
           ▼
3. Thực hiện thay đổi & kiểm chứng (lint / build / test)
```
