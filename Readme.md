# GestureMouse

> **Tiện ích Cử chỉ Chuột, Cuộn Siêu Tốc & Phím Tắt Đa Năng Cho Windows**

**GestureMouse** là một ứng dụng mã nguồn mở nhỏ gọn, mượt mà được phát triển trên nền tảng **AutoHotkey (AHK)**. Ứng dụng giúp tối ưu hóa thao tác làm việc hàng ngày của bạn trên máy tính thông qua các cử chỉ chuột phải thông minh, cơ chế cuộn trang linh hoạt (cuộn trực tiếp, cuộn tự động quán tính, cuộn trang), cùng hệ thống phím tắt điều khiển âm lượng, độ sáng và bảo mật mạnh mẽ.

---

## 🌟 Tính Năng Nổi Bật

### 1. 🖱️ Cử chỉ Chuột Phải Thông Minh (Mouse Gestures)
Giữ phím chuột phải và di chuyển chuột theo các hướng để thao tác nhanh trên các **Trình duyệt web** (Chrome, Microsoft Edge, Firefox, Cốc Cốc, Brave, Opera, Vivaldi...) và **File Explorer**:

| Ký hiệu | Hướng vẽ | Chức năng | Phím tắt tương đương |
| :---: | :--- | :--- | :--- |
| **←** | Sang trái (L) | Quay lại trang trước (Back) | `Alt + Left` |
| **→** | Sang phải (R) | Tiến tới trang tiếp theo (Forward) | `Alt + Right` |
| **↑__** | Lên rồi sang trái (LU) | Chuyển sang tab trước đó | `Ctrl + Shift + Tab` |
| **↓¯¯** | Xuống rồi sang trái (LD) | Chuyển sang tab tiếp theo | `Ctrl + Tab` |
| **__↑** | Phải rồi hướng lên (RU) | Đóng tab hiện tại | `Ctrl + W` |
| **¯¯↓** | Phải rồi hướng xuống (RD) | Tải lại / Làm mới trang | `F5` / `Ctrl + R` |

- **Giao diện HUD trực quan**: Hiển thị biểu tượng và tên cử chỉ mờ nổi bật ở giữa màn hình ngay khi vẽ.
- **Tự động bảo vệ ngữ cảnh**: Không kích hoạt cử chỉ khi con trỏ chuột nằm ngoài cửa sổ đang chọn, hoặc khi đang chọn file trong File Explorer.

---

### 2. 📜 Hệ Thống Cuộn Chuột Toàn Diện (Smart Scrolling)
Áp dụng cho mọi phần mềm có hỗ trợ thanh cuộn (Trình duyệt, VS Code, Word, Excel, Zalo, File Explorer...):

- **Cuộn thủ công mượt mà (Manual Scroll)**: Giữ chuột phải và rê chuột lên / xuống. Tốc độ cuộn thích ứng theo gia tốc di chuyển chuột. Hỗ trợ 2 chế độ trong Cài đặt:
  1. *Kéo nội dung lên xuống* (tương tự lướt màn hình cảm ứng).
  2. *Kéo thanh cuộn lên xuống*.
- **Cuộn tự động theo quán tính (Inertial Auto-Scroll)**: Giữ chuột phải vuốt nhanh lên hoặc xuống rồi thả tay. Trang sẽ tự động trượt đi và giảm tốc dần theo lực ma sát mô phỏng vật lý.
  - *Cách dừng cuộn*: Nhấp chuột trái, chuột giữa hoặc rê chuột nhẹ.
- **Cuộn nhanh từng trang (Page Scroll)**: Giữ chuột phải kết hợp lăn bánh xe chuột để lật trang nhanh chóng (`Page Up` / `Page Down`).

---

### 3. 🔊 Điều Chỉnh Âm Lượng & Độ Sáng Tức Thì
- **Thao tác chuột siêu tốc**:
  - `Giữ chuột trái + Lăn bánh xe`: Tăng / Giảm âm lượng nhanh chóng ở bất kỳ đâu mà không cần click vào thanh Taskbar.
- **Phím tắt âm lượng**:
  - `Win + Lăn chuột` hoặc `Win + PgUp / PgDn`: Tăng / Giảm âm lượng hệ thống.
  - `Ctrl + Shift + M`: Bật / Tắt âm thanh hệ thống (Mute / Unmute).
- **Điều chỉnh độ sáng màn hình**:
  - `F9`: Giảm độ sáng màn hình (làm dịu mắt với lớp phủ màn hình mờ).
  - `F10`: Tăng độ sáng màn hình (trở về trạng thái trong suốt tự nhiên).

---

### 4. ⌨️ Phím Tắt Tiện Ích Đa Năng
- **Bật / Tắt nhanh ứng dụng**:
  - Nhấn `Ctrl + Alt` hoặc **nhấp chuột trái vào biểu tượng ở khay hệ thống (System Tray)** để bật/tắt toàn bộ tính năng cử chỉ chuột và cuộn (Icon màu: *Đang bật*; Icon xám trắng: *Đang tắt*).
- **Khóa bàn phím an toàn (`Ctrl + Alt + L`)**:
  - Vô hiệu hóa toàn bộ bàn phím (và tùy chọn khóa cả nhấp chuột trong cài đặt) để tiện lau chùi bàn phím hoặc tránh trẻ em nghịch bấm.
  - Để mở khóa: Gõ từ khóa `unlock` trên bàn phím.
- **Hẹn giờ tự động khóa màn hình (`Ctrl + Shift + L`)**:
  - Hộp thoại nhập số phút đếm ngược linh hoạt kèm giao diện hiển thị thời gian còn lại bán trong suốt ở góc dưới màn hình.
- **Dán văn bản thuần túy (`Ctrl + Shift + V`)**:
  - Tự động xóa định dạng font chữ, màu sắc, đồng thời cắt tỉa khoảng trắng thừa, tab và dòng trống ở đầu/cuối đoạn văn bản trước khi dán.

---

### 5. 🛡️ Tính Ổn Định & Tương Thích Nâng Cao
- **Khắc phục lỗi mất Hook sau khi Sleep**: Tích hợp module theo dõi sự kiện nguồn điện (`WM_POWERBROADCAST`) và phiên đăng nhập Windows (`WM_WTSSESSION_CHANGE`) giúp tự động khôi phục kết nối hook chuột ngay khi máy thức dậy hoặc mở khóa màn hình.
- **Hỗ trợ Task Manager & Elevated Apps**: Tích hợp sẵn tính năng *Chạy quyền Administrator* và *Cài đặt vào hệ thống (UIAccess)* trực tiếp từ menu khay hệ thống để điều khiển mượt mà ngay cả trên các cửa sổ được nâng quyền của Windows.
- **Đa ngôn ngữ**: Hỗ trợ chuyển đổi nhanh giữa **Tiếng Việt** và **Tiếng Anh** (English) tức thì qua menu khay.

---

## 📂 Cấu Trúc Thư Mục

```text
GestureMouse/
├── Main.ahk                  # File chạy chính của ứng dụng
├── Lib/                      # Các thư viện và module chức năng
│   ├── AutoScroll.ahk        # Xử lý thuật toán cuộn quán tính
│   ├── Brightness.ahk        # Xử lý điều chỉnh độ sáng màn hình
│   ├── Hotkey.ahk            # Hẹn giờ khóa màn hình, Mute, Dán plain text
│   ├── Language.ahk          # Quản lý bảng ngôn ngữ đa ngữ (VI / EN)
│   ├── LockKeyboard.ahk      # Tính năng khóa bàn phím và chuột
│   ├── Menu.ahk              # Quản lý giao diện Cài đặt, Giới thiệu & Khay hệ thống
│   ├── ToggleGesture.ahk     # Quản lý bật/tắt cử chỉ và đổi icon khay
│   └── Volume.ahk            # Điều khiển âm lượng qua chuột và phím tắt
├── image/                    # Hình ảnh biểu tượng, icon cử chỉ, cờ quốc gia
├── tools/                    # Công cụ tạo chứng chỉ số và ký UIAccess
└── Readme.md                 # Tài liệu giới thiệu và hướng dẫn sử dụng
```

---

## 🚀 Hướng Dẫn Sử Dụng

### 1. Chạy trực tiếp từ mã nguồn AutoHotkey:
1. Cài đặt [AutoHotkey v1.1.34+](https://www.autohotkey.com/) (khuyến nghị phiên bản v1.1 Unicode 32/64-bit).
2. Tải mã nguồn `GestureMouse` về máy.
3. Nhấp đúp vào file `Main.ahk` để khởi chạy.

### 2. Tùy chỉnh trong ứng dụng:
- Nhấp đúp vào biểu tượng GestureMouse ở khay hệ thống (hoặc nhấp chuột phải chọn **Cài đặt...**) để tùy chỉnh:
  - Khởi động cùng Windows.
  - Phong cách cuộn chuột (Kéo nội dung hoặc Kéo thanh cuộn).
  - Tùy chọn khóa bàn phím / chuột.
  - Xem danh sách và hình ảnh minh họa cử chỉ.

---

## 👨‍💻 Tác Giả & Bản Quyền

- **Tác giả**: Nguyễn Tri Ân
- **Email liên hệ**: [nguyentrian87@gmail.com](mailto:nguyentrian87@gmail.com)
- **Bản quyền**: © 2026 NGUYENTRIAN. All rights reserved.
