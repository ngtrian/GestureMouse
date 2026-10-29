Phím tắt:
- Mute (Ctrl+Shift+M)
- Page Up (scroll+Up)
- Page Down (scroll+down)
- Khóa màn hình tự động (Ctrl+Shift+L)


Cuộn tự đông, thủ công (cuộn kéo) bằng chuột phải
- auto scroll (up/down) 
- manual scroll (up/down)

Cuộn trang bằng nút wheel
- wheel+PnUp/PnDn

Cử chỉ (bật tắt được):
- Quay lại ⇽
- Tiến tới⇾
- đóng tab (RU)
- refesh
- chuyển tab trước
- chuyển tab sau

MyTooltip



Khác:

- [x] Bật tắt tính năng cuộn, cử chỉ bằng phím tắt (Ctrl+Alt) hoặc khi nhấn vào icon trên system tray (icon chuyển sang màu xám trắng khi tắt)

- [x] đa ngôn ngữ

- khi giữ chuột và kéo lên xuống sẽ kích hoạt trạng thái đang cuộn và nếu không thả tay ra thì vẫn giữ trạng thái chờ cuộn, nên có thể bỏ qua điều kiện khoảng cách để kích hoạt trạng thái cuộn dọc

- Lỗi khi  để lâu hoặc sau khi sleep, các thao tác cử chỉ liên quan đến chuột không hoạt động nữa, các phím tắt khác như mute, autolock screen, lockkeyboard, tăng giảm độ sáng... vẫn hoạt động bình thường

- dừng cuộn tự động khi click chuột

- khi vẽ cử chỉ LU, RU,... thì khi ban đầu vẽ cử chỉ ngang, sau đó vẽ đứng nhưng thay vì vẽ đứng mà vẽ hơi xéo thì nó nhận cử chỉ không đúng, (cần loại bỏ kiểm trang ngang trong trường hợp này, dể dễ vẽ các cử chỉ LU, LD, RU, RD hơn)

- scroll page chưa cuộn được trang nằm sau, đôi khi trở lại cuộn wheel thường vẫn bị page up/down, như kiểu chuột phải chưa được thả ra vậy

- nếu không có cửa sổ nào active, tự nhận diện cửa số trên cùng xem như active, một số cửa sổ không có nút minizebbox 
thì thu nhỏ nó trờ thành thanh nhỏ gọn và nằm cuối màn hình trái (bên trên thanh taskbar)

Nếu cửa sổ đã phục hồi rồi thì đừng phục hồi nữa

Đối với task manager, khi cửa sổ đang active, không thể vẽ cử chỉ trên phạm vi khung cửa sổ taskmanager được, 
phải dời chuột ra ngoài mới vẽ cử chỉ và thu nhỏ nó được, nhưng sau đó cũng không thể phục hồi cửa sổ taskmanager được.

Thu nhỏ ok rồi, nhưng khi phục hồi cửa sổ, gặp 1 cửa sổ không thể phục hồi (như taskmanager) lần thứ nhất nó không phục hồi, 
phải lần 2 nó mới bỏ qua và phục hồi cửa sổ tiếp theo.

Vấn đề nữa là khi đang vẽ cử chỉ bên ngoài cửa số taskmanager, và vẽ sâu vào phạm vi cửa sổ taskmanager thì cử chỉ đó bị đứng lại (tức không ẩn cử chỉ đó)

- Cân nhắc cử chỉ đóng tab thành đóng cửa sổ (khi không phải trình duyệt, explorer)
- thêm cuộn ngang
- khóa chỉ cho phép tương tác với cửa sổ đang active 
- Ngăn cử chỉ khi đang nhấn nút phải

STAGS MANAGER:
- Hiển thị các cửa số đang hoạt động (app có cửa sổ đang chạy) giống như stags manager macos nhưng nằm bên phải desktop
- Ảnh preview ứng dụng lấy từ ảnh preview khi rê chuột vào các ứng dụng đang mở trên taskbar của windows
- khi nhấn vào 1 stag sẽ thu nhỏ các cửa sổ (minimize) khác lại, đặt cửa sổ chính ở full màn hình (trừ ra khu vực chứa stags manager)




*TẠO CHỨNG CHỈ
Yêu cầu:
- Win64 OpenSSL
- signtool.exe
 
1.Chạy 3 lệnh sau để tạo 3 file: 
-private.key: Khóa bí mật.
-certificate.crt: Chứng chỉ công khai.
-certificate.pfx: File tổng hợp để ký (dùng với signtool).


openssl genrsa -out private.key 2048

openssl req -new -x509 -key private.key -out certificate.crt -days 3650 -subj "/CN=NGUYENTRIAN" -config "openssl.cnf"

openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -password pass:mypassword

Giải thích:
genrsa: Tạo khóa bí mật RSA 2048-bit, lưu thành private.key.

req -new -x509: Tạo chứng chỉ tự ký (certificate.crt), hết hạn sau 3650 ngày (10 năm), tên là "MySelfSignedCert".

pkcs12: Kết hợp khóa và chứng chỉ thành file .pfx (định dạng dùng để ký), mật khẩu là mypassword.

2.ký file bằng chứng chỉ tự tạo: pass la nguyentrian
signtool.exe sign /f "certificate.pfx" /p "nguyentrian" "GestureMouse.exe"

3.Thêm Countersignature (Time Stamping) miễn phí từ Sectigo
signtool.exe sign /f "certificate.pfx" /p "nguyentrian" /tr "http://timestamp.sectigo.com?td=sha256" /td sha256 "GestureMouse.exe"


