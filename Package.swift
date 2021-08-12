// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AnalogDial",
  platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)],
  products: [
    .library(
      name: "AnalogDial",
      targets: ["AnalogDial"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "AnalogDial",
      dependencies: []),
  ]
)
