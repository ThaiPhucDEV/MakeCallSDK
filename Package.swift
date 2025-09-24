// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MakeCallSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "MakeCallSDK", targets: ["MakeCallSDK"]),
    ],
    dependencies: [
        .package(url: "https://gitlab.linphone.org/BC/public/linphone-sdk-swift-ios.git", from: "5.4.5"),  // Hoặc URL chính thức của linphone-swift SPM
    ],
    targets: [
        .target(
            name: "MakeCallSDK",
            dependencies: [
                .product(name: "linphonesw", package: "linphone-sdk-swift-ios")  // Khai báo dependency
            ],
            path: "Sources/MakeCallSDK"
        ),
    ]
)
