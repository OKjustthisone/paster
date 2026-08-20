// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Paster",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Paster", targets: ["Paster"])
    ],
    targets: [
        .executableTarget(
            name: "Paster",
            path: "Sources"
        )
    ]
)
