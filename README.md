# 📞 MakeCallSDK

**MakeCallSDK** là thư viện iOS viết bằng Swift, giúp tích hợp tính năng **VoIP/SIP Call** (gọi điện thoại qua internet) vào ứng dụng của bạn.

SDK hỗ trợ **iOS 13+**, dễ cài đặt, và có thể mở rộng UI để tùy biến màn hình cuộc gọi.

---

## ✨ Tính năng

- Khởi tạo và đăng ký SIP account
- Thực hiện và kết thúc cuộc gọi
- Theo dõi trạng thái cuộc gọi (idle, ringing, connected, ended...)
- Quản lý trạng thái đăng ký SIP và kết nối mạng
- Tùy biến giao diện cuộc gọi bằng SwiftUI hoặc UIKit

---

## 📦 Cài đặt

Bạn có thể cài đặt **MakeCallSDK** qua **Swift Package Manager (SPM)**.

### Swift Package Manager (SPM)

**Tóm tắt các bước:**

1. Mở **Xcode**, chọn project trong **Project Navigator**.
2. Vào tab **Package Dependencies**.
3. Nhấn nút **+** và nhập URL sau vào thanh tìm kiếm:
   ```
   https://gitlab.mitek.vn/mitek-public/sdk/micall/make-call-sdk-ios
   ```
4. Chọn **phiên bản** hoặc **nhánh** mong muốn.
5. Nhấn **Add Package** để hoàn tất.

---

## 🚀 Hướng dẫn sử dụng

### Import SDK

```swift
import MakeCallSDK
```

### Cấu hình SDK

```swift
let config = CallConfig(
    ext: "<YOUR_EXTENSION>",
    password: "<YOUR_PASSWORD>",
    domain: "<YOUR_SIP_DOMAIN>",
    sipProxy: "<YOUR_SIP_PROXY>",
    port: 5060,
    transport: "tcp" // hoặc "udp", "tls", "wss"
)

MakeCallSDK.shared.initialize(config: config)
```

⚠️ **Lưu ý:** Thay `<YOUR_EXTENSION>`, `<YOUR_PASSWORD>`, `<YOUR_SIP_DOMAIN>`, `<YOUR_SIP_PROXY>` bằng thông tin tài khoản SIP thật do nhà cung cấp dịch vụ VoIP cung cấp.

### Thực hiện cuộc gọi

```swift
MakeCallSDK.shared.startCall(phoneNumber: "0901234567") { result in
    switch result {
    case .success:
        print("📞 Cuộc gọi đã bắt đầu")
    case .failure(let error):
        print("❌ Lỗi: \(error.localizedDescription)")
    }
}
```

### Kết thúc cuộc gọi

```swift
MakeCallSDK.shared.endCall()
```

---

## ⚠️ Quyền bắt buộc

Trong `Info.plist`, thêm:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Ứng dụng cần quyền Microphone để thực hiện cuộc gọi.</string>
```

Nếu hỗ trợ Bluetooth headset:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Ứng dụng cần quyền Bluetooth để kết nối tai nghe.</string>
```

---

## 📚 Tài liệu

Để biết thêm chi tiết về cách sử dụng và tùy biến SDK, vui lòng tham khảo tài liệu đầy đủ tại repository chính thức.

## 🆘 Hỗ trợ

Nếu gặp vấn đề trong quá trình sử dụng, vui lòng tạo issue trên repository hoặc liên hệ team phát triển.
