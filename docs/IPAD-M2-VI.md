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

**Bản mới nhất là IPA 1009**, đã [phát hành trên GitHub](https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1009).
Mở **Settings → App Updates → Check Now**, tải rồi chuyển sang LCSign ký/cài
với cùng bundle ID. Đóng và mở lại app/desktop; kiểm tra Installed hiển thị 1009.

Log **1008** tiếp theo đã khác lỗi zygote: `mmap(NULL, 0x810000, PROT_NONE,
MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, ...)` trả `ENOMEM`, rồi Chromium báo
`pthread_create: Resource temporarily unavailable (11)` và `SIGTRAP`.
Vùng 0x810000 là dạng stack glibc 8 MiB kèm guard 64 KiB. Log không đủ để
kết luận RAM vật lý đã hết hoặc chính xác giới hạn nào từ chối cấp phát.

Bản **1009** cho phép private PROT_NONE từ 1 MiB dùng demand-zero:
giữ nguyên dung lượng stack và guard nhưng chỉ cấp backing khi trang được dùng.
Ngưỡng cũ 16 MiB bỏ sót stack 8 MiB. Bài thử macOS cố tình từ chối host mmap
0x810000, kiểm tra 48 stack cùng tồn tại, dữ liệu riêng, zero-fill, guard,
mprotect và unmap. Crash mới giữ số đo host virtual/resident/footprint,
memory allowance và anonymous budget nếu có lỗi cấp phát. Đây chưa phải
xác nhận Chromium chạy thành công trên iPad.

Sửa zygote đã có từ [IPA 1008](https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1008).

Log build **1007** mới đã đi qua bước nạp Chromium, rồi `SIGTRAP` tại
`zygote_host_impl_linux.cc:228`: **Zygote process exited prematurely with exit code 127**.
Điều này xác nhận lỗi hiện tại ở đường khởi tạo zygote/sandbox; log chưa chỉ ra
chính xác thao tác bên trong tiến trình con khiến nó trả 127.

Bản sửa sau build 1007 cài fragment `/etc/chromium.d/90-linuxrunner` khi mở
desktop Debian. Đây là điểm cấu hình chính thức mà launcher Debian đọc; chỉ
export `CHROMIUM_FLAGS` từ desktop không đủ vì `/usr/bin/chromium` đặt lại biến
này trước khi đọc các fragment. Biểu tượng Chromium thường trong KDE và lệnh
`chromium` đều nhận `--no-sandbox --no-zygote`, phần mềm GPU và V8 jitless.
Không cần cài lại gói Chromium hoặc chạy lại toàn bộ setup. Mở desktop mới
sau khi cập nhật app để áp dụng. Các renderer vẫn là tiến trình riêng;
không thêm `--single-process` hoặc xóa profile.

Thử ngay trên build 1007, trong **Konsole của KDE**:

```bash
chromium --no-sandbox --no-zygote --disable-gpu --disable-gpu-compositing --js-flags=--jitless --user-data-dir="$HOME/.config/linuxrunner/chromium" about:blank
```

Lệnh này dùng profile riêng, không xóa lịch sử/profile Chromium đang có. Nếu
vẫn dừng, gửi log mới: cần kiểm tra lỗi sau khi đã bỏ đường zygote. Cấu hình
này giảm các lớp cách ly của Chromium trong Linux; sandbox iPadOS vẫn được giữ.

Trong log cũ của build **900**, `execve` trả `ENOMEM` khi host từ chối ánh xạ đoạn ELF khoảng **237 MiB** của `/usr/lib/chromium/chromium` (file khoảng 294 MiB). PC và LR sau đó đều trỏ vào vùng không còn được map.

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

Kiểm tra C độc lập đã qua trên Windows. [Bitrise build #7](https://app.bitrise.io/app/1cb085dc-5a2d-441e-947e-28ceebae9cd4/build/69de74f7-8015-4f15-9e6c-dbc7bc4e64ce) đã thành công toàn bộ: kiểm tra runtime/RFB trên macOS ARM64, kiểm tra updater, biên dịch Metal/Xcode, kiểm tra IPA và đăng artifact ZIP. IPA build **1007**, source `231c8970644abea0d4c8a226c63f863f63d28749`, đã [phát hành trên GitHub](https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1007). Đã tải thử manifest và IPA công khai, đối chiếu SHA-256 với artifact Bitrise. Độ mượt, JIT, chuyển file sang LCSign và khả năng mở Chromium vẫn cần kiểm tra trên iPad; chưa có số đo tăng tốc trên máy thật.

[Bitrise build #8](https://app.bitrise.io/app/1cb085dc-5a2d-441e-947e-28ceebae9cd4/build/98ecbb68-b1d6-4f98-82d5-7df25ae2d946)
đã thành công toàn bộ cho sửa Chromium, tạo IPA **1008**, source
`bab56ca131f786379c3fe537a47455ef2af7887c`. Đã đối chiếu 95 tài nguyên trong
IPA với source và tải thử manifest/IPA/checksum công khai từ release.
SHA-256: `b0028a4d5648babc1ce9cb67a8e8fa42db5e72da6be042a6484c40dd89b9a586`.
Khả năng mở Chromium thật vẫn cần người dùng thử trên iPad.

[Bitrise build #9](https://app.bitrise.io/app/1cb085dc-5a2d-441e-947e-28ceebae9cd4/build/26f0d146-83aa-4cc1-890f-088cc17dac2b)
đã thành công cho sửa stack, tạo IPA **1009**, source
`a46e9090797650d711bc924a63a527da240c71d5`. Test macOS xác nhận 48 stack
0x810000 cùng tồn tại khi host bị ép từ chối mapping đó, giữ guard EFAULT,
zero-fill, reprotection, dữ liệu riêng và unmap. DiagnosticsTests cũng qua.
Đã kiểm tra source hashes, 95 resources và tải thử IPA/checksum công khai.
SHA-256: `febb90e233a636cd537551b6cd2941ef774e2f006fad54312a78491899cf042c`.
Chưa có kết quả thử Chromium trên iPad với bản 1009.

## 7. Tự tải bản cập nhật và chuyển sang LCSign

Trong bản M2 mới: **Settings → App Updates**.

- Mặc định tự kiểm tra khi mở app/quay lại app, cách nhau ít nhất 6 giờ trong cùng lần chạy. Có thể dùng **Check Now** để kiểm tra ngay.
- Chỉ lấy bản phát hành công khai ở `sonnx0868/LinuxRunner`, đúng nhánh JIT hoặc interpreter. Không tự thay bằng bản upstream.
- App so sánh số build, tải IPA về bộ nhớ đệm, kiểm tra dung lượng và SHA-256 trước khi đưa sang công cụ ký. Giữ app ở foreground trong lúc tải; có thể hủy và tải lại.
- Khi tải xong, app mở **Open In**. Chọn **LCSign**, sau đó ký/cài trong LCSign. File tải xong có thể gửi lại qua **Send IPA to LCSign**.
- Dùng cùng bundle ID và cấu hình ký đang dùng để cập nhật bản đã cài. Đổi danh tính app có thể tạo một app riêng với vùng dữ liệu khác.

Đã kiểm tra tĩnh bản [LCSign 1.0 build 6](https://github.com/qbap/ONEJailbreak/blob/main/LCSign-1.0-6.ipa): bundle ID `com.huami.LoadController`, đăng ký nhận file IPA và scheme `loadcontroller`. Chưa xác minh được giao thức deep link nhận IPA từ app khác. Vì vậy dùng cơ chế chuyển tài liệu của iPadOS; vẫn cần một lần chọn LCSign. App không thể tự ký/cài bằng chứng chỉ của LCSign hoặc âm thầm vượt bước chọn của iPadOS. Chuyển file trên iPad cần được kiểm tra bằng bản cài thật.

### Phát hành bản mới cho updater

Bitrise tạo `update-m2-jit.json` hoặc `update-m2-interpreter.json` từ chính IPA đã kiểm tra. Build number trên Bitrise là `1000 + BITRISE_BUILD_NUMBER`. ZIP artifact có IPA, SHA-256, manifest và log.

Sau khi tải và giải nén artifact, đăng IPA cùng manifest bằng tài khoản đã lưu trong Git:

```bash
python3 scripts/publish-update.py build/releases/LinuxRunner-M2-YES.ipa --git-credential
```

Script tạo draft, tải đủ IPA/manifest/checksum lên rồi mới công khai release. Trong CI có thể dùng biến bí mật `GITHUB_RELEASE_TOKEN` thay cho `--git-credential`; cần tự cấp quyền phát hành cho repo. Token không được nhúng vào app. Build Bitrise đơn thuần chưa tự tạo GitHub Release nếu chưa cấu hình quyền này.
