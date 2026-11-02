# Workspace Rules - GestureMouse

## 1. Không tự động biên dịch file exe
- Tuyệt đối **không tự ý biên dịch** (`Ahk2Exe`) mã nguồn `.ahk` thành file thực thi `.exe` (`GestureMouse.exe`, `GestureMouse1.exe`, `GestureMouse2.exe`...).
- Chỉ thực hiện biên dịch khi người dùng có yêu cầu rõ ràng.

## 2. Luôn lưu file ở chuẩn UTF-8 with BOM
- Tất cả các file mã nguồn AutoHotkey (`.ahk`), cấu hình và tài liệu chứa tiếng Việt **bắt buộc phải được lưu ở chuẩn UTF-8 có BOM (UTF-8 with BOM / Byte Order Mark `0xEF, 0xBB, 0xBF`)**.
- Tuyệt đối không lưu ở dạng UTF-8 không BOM hay ANSI, vì AutoHotkey v1 sẽ đọc nhầm thành ANSI khiến giao diện và menu tiếng Việt bị lỗi font (mojibake).

## 3. Gợi ý nội dung commit Git sau mỗi lần triển khai code
- Mỗi khi hoàn thành chỉnh sửa mã nguồn hoặc triển khai tính năng mới, luôn chủ động gợi ý nội dung commit Git (Commit Message) chuẩn, ngắn gọn và rõ ràng (theo định dạng Conventional Commits) ở cuối phản hồi.
- **Chỉ cung cấp duy nhất phần nội dung commit** (không kèm theo các dòng lệnh git như `git add`, `git commit -m`...) để người dùng sao chép và dán nhanh vào giao diện Git / VS Code.
