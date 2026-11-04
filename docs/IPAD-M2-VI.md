# LinuxRunner cho iPad Pro M2, RAM 16 GB

Nhánh `codex/ipad-m2-performance`, dựa trên LinuxRunner 1.1.0 build 900. Mục tiêu: Debian 13 ARM64, KDE Plasma X11, người dùng thường có `sudo`, iPadOS 27.

## 1. Build bằng Bitrise

Thư mục `F:\LinuxRunner` trên Windows đã chứa các thay đổi. Bản `LinuxRunner-M2.patch` dùng cho một clone sạch khác dựa trên commit `d141978`; không áp dụng lại vào thư mục đã sửa. ZIP mã nguồn không chứa các submodule đã tải; Bitrise sẽ tải đúng revision từ Git.

Ví dụ áp dụng patch vào fork mới của bạn:

```powershell
git clone https://github.com/TEN_CUA_BAN/LinuxRunner.git LinuxRunner-M2
cd LinuxRunner-M2
git switch -c codex/ipad-m2-performance d141978
git apply --index F:/LinuxRunner-M2.patch
git commit -m "Optimize LinuxRunner for iPad M2 and guest Vietnamese input"
git push origin codex/ipad-m2-performance
```

Thay `TEN_CUA_BAN` bằng tên GitHub của bạn. Các lệnh trên tạo nhánh trong fork để Bitrise đọc được mã mới.

1. Đưa nhánh đã sửa lên repository GitHub của bạn. Nếu dùng repository gốc làm điểm bắt đầu, fork rồi áp dụng bản patch đi kèm trước khi push.
2. Trong Bitrise, kết nối repository và chọn nhánh chứa thay đổi.
3. Chọn cấu hình từ repository, đường dẫn **`bitrise.yml`**.
4. Chọn máy **macOS Apple Silicon / ARM64**, có **Xcode đầy đủ và SDK hỗ trợ iPadOS 27**. Chọn stack đang có trong Bitrise; file cấu hình không gán tên stack có thể hết hạn.
5. Chạy workflow **`m2-jit`**. Workflow tải dependency đúng phiên bản, chạy kiểm tra, build Metal và tạo IPA. Lần build sạch cần tải nhiều dữ liệu; giữ đủ thời gian build và dung lượng đĩa.
6. Sau khi build thành công, mở **Apps & Artifacts**, tải `LinuxRunner-M2-YES.ipa`. Đây là IPA ký ad-hoc; dùng công cụ ký/cài bạn đang dùng để cấp chữ ký cho iPad.

Nếu chưa sử dụng được StikDebug, build **`m2-interpreter`**. Bản này tránh chi phí của backend JIT khi JIT chưa được cấp quyền. Cả hai bản giữ bundle ID `dev.linuxrunner.app`; khi ký/cài, giữ định danh cũ để tiếp tục dùng dữ liệu đã có. Nên xuất bản sao Debian trước khi thay app.

Không cần đưa chứng chỉ hoặc mật khẩu Apple vào mã nguồn. Workflow hiện tạo IPA để bạn ký sau.

## 2. Mở app và bật JIT

1. Cài và thiết lập ghép đôi StikDebug trên iPad trước.
2. Mở LinuxRunner bản `m2-jit`. Với profile iPad RAM 16 GB, **Open StikDebug on launch** mặc định bật.
3. App yêu cầu StikDebug cấp JIT **một lần trong mỗi lần khởi chạy app**. Trên iPadOS 27, yêu cầu có `script-name=universal`, theo cơ chế mã nguồn hiện có cho iOS 26 trở lên.
4. Khi StikDebug hoàn tất, quay lại LinuxRunner.
5. Vào **Settings → Execution Engine / StikDebug**. Chỉ coi JIT đã chạy khi thấy **JIT Active** cùng số khối mã đã dịch tăng lên trong lúc dùng Linux. `JIT Initializing` nghĩa là vùng mã đã được kiểm tra nhưng chưa có mã guest được dịch.

Nếu không được, dùng **Attach with StikDebug**, rồi **Activate JIT Now**. Xem thông báo lỗi ngay trong trang đó. Không có StikDebug/quyền thực thi phù hợp thì app tiếp tục bằng interpreter. Việc app tự mở StikDebug chưa đồng nghĩa đã được cấp JIT. Quy trình iPadOS 27 vẫn cần xác nhận trên máy thật.

App giữ cơ chế ghi nhận lần kích hoạt gây crash để không tự lặp lại cách kích hoạt đó. Tắt **Open StikDebug on launch** nếu không muốn chuyển app lúc mở.

## 3. Cài Chromium và bộ gõ tiếng Việt

**Thực hiện trong Konsole/Terminal bên trong màn hình KDE**, đăng nhập bằng người dùng Debian thường có quyền `sudo`.

Sau khi cài bản mới và mở desktop ít nhất một lần, chạy:

```bash
bash /home/mobile/Downloads/.linuxrunner/gui/setup-debian-m2.sh
```

Script cài Chromium, Fcitx5, Unikey, phông chữ; thiết lập biến môi trường cho KDE và thêm biểu tượng **Chromium (LinuxRunner M2)**. Nhập mật khẩu `sudo` khi được hỏi. Script dùng APT của Debian, cần mạng và dung lượng tải gói.

Sau đó:

1. Dừng rồi mở lại desktop trong LinuxRunner để nhận biến môi trường mới.
2. Mở **Fcitx 5 Configuration** trong menu KDE, hoặc chạy `fcitx5-configtool`.
3. Trong **Input Method**, thêm **Keyboard – English (US)** và **Unikey**. Bỏ **Only Show Current Language** nếu không thấy Unikey.
4. Trong cấu hình Unikey, chọn **Telex** hoặc **VNI**, bảng mã **Unicode**.
5. Mở Konsole mới. Dùng **Ctrl+Space** bật/tắt bộ gõ. Thử `tieengs Vieetj` với Telex; kết quả cần là `tiếng Việt`.

### Bàn phím iPad

- Thêm bàn phím **English (US)** trong **Cài đặt iPad → Cài đặt chung → Bàn phím → Bàn phím**. Chọn English khi nhập trong LinuxRunner.
- Phím trên bàn phím vật lý gửi theo vị trí phím US, bỏ qua chữ đã qua bộ gõ iPadOS. Linux/Fcitx5 nhận `aa`, `aw`, `dd` và tự xử lý.
- Desktop giữ **Ctrl+Space** cho bộ gõ Linux. Shift, Ctrl, Alt và Command được gửi thành Shift, Ctrl, Alt và Super. Tổ hợp toàn hệ thống iPadOS vẫn có thể do iPadOS giữ.
- Bàn phím ảo yêu cầu ASCII/English, tắt tự sửa, viết hoa và dấu câu thông minh. API công khai không ép được English nếu iPad chưa bật bàn phím đó; vì vậy bước thêm English vẫn cần thiết.
- Dán văn bản Unicode được giữ nguyên. Không bỏ dấu tiếng Việt trong nội dung dán.

## 4. Chromium chạy nhẹ hơn

Mở **Chromium (LinuxRunner M2)** trong menu KDE, hoặc chạy:

```bash
~/.local/bin/linuxrunner-chromium
```

Cấu hình dùng profile riêng ở `~/.config/linuxrunner/chromium`, giới hạn mềm hai tiến trình renderer, tắt extension/tác vụ nền, dùng đồ họa phần mềm và V8 jitless với giới hạn heap 512 MB mỗi V8 isolate. Chromium vẫn có thể tạo thêm tiến trình để giữ ranh giới bảo mật. Giới hạn heap có thể khiến trang nặng báo thiếu bộ nhớ; đây không phải giới hạn tổng RAM của trình duyệt.

JIT của **LinuxRunner** vẫn có thể hoạt động khi V8 của Chromium đặt `jitless`: hai lớp độc lập. V8 jitless ưu tiên tương thích; chưa có phép đo chứng minh nó nhanh hơn cho mọi trang.

Launcher dùng `--no-sandbox --no-zygote` vì sandbox Linux của Chromium chưa được hỗ trợ đầy đủ trong runtime. Sandbox iPadOS vẫn do iPadOS quản lý. Không dùng `--single-process` hoặc tắt site isolation.

Để nhẹ nhất trong KDE:

- Bắt đầu ở **960×540**, tăng lên **1024×768** nếu vẫn đáp ứng tốt. Nhiều điểm ảnh làm CPU phải vẽ và truyền nhiều dữ liệu hơn.
- Mở ít tab, thử 1–3 tab trước. Đóng Blender và app nặng khi dùng Chromium.
- Bật **Settings → Desktop Environment → Plasma Compatibility Mode**. Chế độ này bỏ Qt GLX, dùng Qt Quick software, tắt compositor/effect KWin. Khởi động lại desktop sau khi đổi.
- Trình bày khung hình Metal mặc định bật trong profile M2; nội dung Chromium vẫn dùng software. Đồ họa 3D guest là lựa chọn riêng trong Settings → Graphics và còn thử nghiệm.
- Màn hình ngoài có trần 60 Hz khi trình bày bằng Metal, hạ về 30 Hz nếu nóng hoặc Low Power Mode. Đây là trần cập nhật, không cam kết đạt 60 FPS.

### Về crash Chromium trong log bạn gửi

Log cho thấy `execve` trả `ENOMEM` khi host từ chối ánh xạ đoạn ELF khoảng **237 MiB** của `/usr/lib/chromium/chromium` (file khoảng 294 MiB). PC và LR sau đó đều trỏ vào vùng không còn được map.

Bản sửa giữ ảnh tiến trình cũ đến khi nạp thành công, giải phóng ảnh nạp dở và trả errno nếu nạp thất bại. Nhờ vậy tránh lỗi thứ hai: quay về mã đã bị xóa. Điều này **chưa đảm bảo** iPadOS chấp nhận ánh xạ file Chromium lớn. Cờ giảm tiến trình chỉ có tác dụng khi các tiến trình nạp được.

Nếu vẫn lỗi, chạy trong Konsole:

```bash
~/.local/bin/linuxrunner-chromium --enable-logging=stderr 2>&1 | tee ~/chromium-m2.log
```

Gửi lại `~/chromium-m2.log` và crash report của **bản mới**. Có thể dùng Browser của LinuxRunner hoặc Firefox để kiểm tra khả năng duyệt web trong lúc xác định lỗi còn lại; Browser của LinuxRunner dùng Qt WebEngine, không phải gói Chromium Debian.

## 5. Discord và Photoshop

- **Discord:** mở `https://discord.com/app` trong trình duyệt. Discord không phát hành desktop Linux ARM64 chính thức cho môi trường này. Voice/video phụ thuộc mic, âm thanh và WebRTC của runtime; chưa được xác nhận trên iPad này.
- **Photoshop:** Adobe không có Photoshop native cho Debian ARM64. Dùng Photoshop trên iPad, hoặc thử Photopea tại `https://www.photopea.com`. Photoshop Windows qua Wine/x86 không nằm trong cấu hình đã kiểm tra.

## 6. Thay đổi và kiểm tra

- Runtime có tùy chọn biên dịch cho Apple M2; không khai thêm HWCAP chưa hỗ trợ cho Linux.
- Ngân sách anonymous của cả Linux có thể tăng từ 4 GiB, tối đa 8 GiB, chỉ khi iPadOS báo hạn mức còn lại phù hợp. Chừa ít nhất 1 GiB cho phần khác; RAM công bố riêng cho tiến trình Linux vẫn giữ 4 GiB. Đây là trần cấp phát, không phải RAM đặt trước hoặc quyền dùng toàn bộ 16 GB.
- RFB hỗ trợ CopyRect, giảm truyền pixel khi server dùng được phép sao chép; xử lý vùng chồng lấn, không cấp phát bộ đệm cả vùng. Không bật XRecord hoặc đổi cách phát hiện cuộn chưa được kiểm tra.
- Cuộn trackpad giữ chuyển động lẻ, chuyển nhiều bước theo quãng cuộn, hỗ trợ ngang. Trạng thái nút chuột thuộc từng màn hình.
- Bàn phím vật lý US và bộ gõ Linux tách khỏi Telex của iPadOS.

Kiểm tra độc lập với compiler C:

```bash
bash scripts/test-m2-portable.sh
```

Trên macOS ARM64 đã có dependency:

```bash
bash scripts/test-m2-macos.sh
python3 scripts/generate-gui-support-manifest.py --check
```

Bitrise chạy các kiểm tra trước khi build IPA. Kiểm tra lỗi host `mmap` trả `ENOMEM` sau khi nạp một phần ELF lặp 32 lần, kiểm tra robust futex list còn nguyên và chạy `exec` tiếp theo. Fixture nhỏ dùng một lần, không cần tải Debian.

Kiểm tra C độc lập đã qua trên Windows. Phần Objective-C/Swift, runtime macOS, IPA và độ mượt trên iPad cần kết quả Bitrise/máy thật; chưa có số đo tăng tốc hoặc IPA được xác nhận từ máy Windows này.
