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
