# Tiếp tục LinuxRunner trên máy ở nhà

## Cách đơn giản: mở chat mới từ source GitHub

Clone đúng branch bên dưới, mở thư mục trong Codex rồi gửi:

> Đọc docs/CONTINUE-AT-HOME-VI.md rồi tiếp tục LinuxRunner cho iPad Pro M2
> 16 GB, iPadOS 27, Debian 13 aarch64. Ưu tiên tốc độ và độ mượt. Bản sửa
> Chromium đã build và phát hành IPA 1008. Tiếp tục dựa trên kết quả thử
> bản 1008 trên iPad; không coi Chromium đã chạy được khi chưa có xác nhận
> từ thiết bị.

Source và ghi chú đủ để tiếp tục công việc; cách này không sao chép toàn bộ
lịch sử chat. GitHub và Bitrise ở máy nhà cần đăng nhập tài khoản của bạn.

### Trạng thái chính xác lúc chuyển máy

- Commit sửa Chromium: `225e46b` (đã đẩy lên branch bên dưới).
- Kiểm tra shell trên Windows và manifest 95 resources đã qua.
- Bitrise build #8 đã thành công toàn bộ; IPA 1008 có source
  `bab56ca131f786379c3fe537a47455ef2af7887c`.
- Build: https://app.bitrise.io/app/1cb085dc-5a2d-441e-947e-28ceebae9cd4/build/98ecbb68-b1d6-4f98-82d5-7df25ae2d946
- Release: https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1008
- IPA: https://github.com/sonnx0868/LinuxRunner/releases/download/m2-build-1008/LinuxRunner-M2-YES.ipa
- SHA-256: `b0028a4d5648babc1ce9cb67a8e8fa42db5e72da6be042a6484c40dd89b9a586`.
- Đã tải IPA công khai không đăng nhập, đối chiếu hash với artifact Bitrise;
  kiểm tra 95 tài nguyên trong IPA khớp source, có config Chromium mới.
- Build #7 / IPA 1007 là bản trước sửa zygote.
- Việc tiếp theo: cài 1008, mở desktop mới và thử Chromium trên iPad.
  Nếu vẫn crash, cần log mới của 1008 để xác định lỗi còn lại.

## Source

- Repo: https://github.com/sonnx0868/LinuxRunner
- Branch: `codex/ipad-m2-performance`
- Bản hiện tại: https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1008
- Bản đã phát hành trước sửa zygote: https://github.com/sonnx0868/LinuxRunner/releases/tag/m2-build-1007
- Người dùng: iPad Pro M2, 16 GB RAM, iPadOS 27; Debian 13 aarch64, user thường có sudo.
- Ưu tiên tốc độ dịch mã và độ trễ khung hình. Chưa đo tốc độ thực tế trên iPad.

```bash
git clone --branch codex/ipad-m2-performance https://github.com/sonnx0868/LinuxRunner.git
cd LinuxRunner
```

Hiện source ở `F:\LinuxRunner`, còn chat đang mở từ project `Madeira`.
Trên máy nguồn, dùng Add project mở `F:\LinuxRunner`, rồi chuyển chat hiện tại
vào project LinuxRunner bằng sidebar. Lưu thư mục LinuxRunner thành project
ở máy nhà để Codex có thể nhận Hand off đúng repo. Nếu máy nhà không được
nhận là cùng repo, kiểm tra remote: máy nguồn có `origin` là upstream
`https://github.com/mxhm11cr/LinuxRunner.git` và `fork` là repo sonnx0868.
Kết nối các máy tại Settings → Connections. Trong cuộc chat hiện tại, chọn
vị trí chạy ở chân chat → máy nhà → Hand off. Cần cùng tài khoản/workspace;
tính năng phụ thuộc phiên bản app và quyền tài khoản. Remote control cho phép
mở lại chat trên máy nguồn; Hand off mới chuyển nơi thực thi và trạng thái Git.

Tài liệu OpenAI: https://developers.openai.com/codex/remote-connections

Nếu không thấy máy nhà trong danh sách, kiểm tra đã lưu project cùng repo trên
máy đó và đã kết nối hai máy. Chỉ đăng nhập cùng tài khoản không tự chuyển chat
local sang máy khác. Hand off sẽ ngắt lượt trả lời đang chạy. Đợi chuyển xong
rồi mới tắt máy nguồn.

Nếu tài khoản chưa có Hand off, clone repo ở trên, mở chat mới trong project
LinuxRunner trên máy nhà rồi gửi: "Đọc docs/CONTINUE-AT-HOME-VI.md và tiếp tục
sửa Chromium cho iPad M2." Cách này tiếp tục được source và ghi chú, nhưng
không mang nguyên lịch sử chat cũ sang.

## Lỗi Chromium mới

Crash build 1007: SIGTRAP/BRK sau thông báo
`zygote_host_impl_linux.cc:228: Zygote process exited prematurely with exit code 127`.
Đã nạp được ELF Chromium; không phải crash quay về vùng unmapped sau exec ENOMEM
trong log build 900. Không khẳng định nguyên nhân nội bộ của exit 127 khi chưa có trace con.

Sửa trong commit kèm tài liệu này:

- `configure-chromium.sh` cài config vào `/etc/chromium.d/90-linuxrunner` bằng
  cơ chế Debian hỗ trợ, trước khi session chuyển sang user thường.
- `chromium-compat.conf` áp dụng `--no-sandbox --no-zygote`, software GPU,
  renderer limit 2 và V8 jitless cho biểu tượng/lệnh Chromium thường.
- Không thay ELF, gói, profile hoặc desktop file của người dùng.
- Test shell tái hiện việc Debian reset `CHROMIUM_FLAGS`, kiểm tra cập nhật
  idempotent, giữ profile/config khác, opt-out và symlink nếu filesystem hỗ trợ.
- Kiểm tra mở Chromium thật trên iPad vẫn cần người dùng thử.

## Build và phát hành

Bitrise: https://app.bitrise.io/app/1cb085dc-5a2d-441e-947e-28ceebae9cd4
Workflow `m2-jit`; build number IPA là 1000 + số build Bitrise.
Default branch và `/bitrise.yml` đã cấu hình đúng.
IPA ad-hoc signed, cần người dùng ký lại bằng LCSign cùng bundle ID cũ.
Bitrise artifact là ZIP để tránh yêu cầu embedded.mobileprovision của bước deploy.

Sau khi tải artifact, kiểm tra checksum và publish bằng script
`scripts/publish-update.py <IPA> --git-credential` với GitHub login của chủ repo.
Máy nhà cần tự đăng nhập GitHub/Bitrise; không sao chép token, cookie hoặc auth.json
vào repo. App updater lấy public GitHub Releases, không chứa token.

Các file nguồn trước đó có sửa exec rollback, profile M2, CopyRect, input US thô,
cuộn trackpad, tự yêu cầu StikDebug và bộ gõ Fcitx5/Unikey ở Linux.
JIT chỉ xác nhận khi `JIT Active` và số khối mã/segments tăng.
