// swift-tools-version:5.1

//
//  Package.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "FluentMongo",
    products: [
      .library(name: "FluentMongo", targets: ["FluentMongo"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", /*.upToNextMajor(from: "1.0.0-alpha.3.1"),*/ .branch("master")),
      .package(url: "https://github.com/vapor/async-kit.git", /*.upToNextMajor(from: "1.0.0-alpha"),*/ .branch("master")),
      .package(url: "https://github.com/mongodb/mongo-swift-driver.git", .upToNextMinor(from: "0.1.3")),
      .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "FluentMongo", dependencies: ["FluentKit", "AsyncKit", "MongoSwift", "Logging"]),
        .testTarget(name: "FluentMongoTests", dependencies: ["FluentMongo", "FluentBenchmark"])
    ]
)
