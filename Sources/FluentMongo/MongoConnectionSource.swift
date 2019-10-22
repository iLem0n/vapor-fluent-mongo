//
//  MongoConnectionSource.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import AsyncKit
import FluentKit

public struct MongoConnectionSource: ConnectionPoolSource {

    // MARK: Initialization

    public init(
        configuration: MongoConfiguration,
        threadPool: NIOThreadPool,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.threadPool = threadPool
        self.eventLoop = eventLoop
    }

    // MARK: Managing Connection Source

    private let configuration: MongoConfiguration

    private let threadPool: NIOThreadPool

    // MARK: ConnectionPoolSource

    public var eventLoop: EventLoop

    public func makeConnection() -> EventLoopFuture<MongoConnection> {
        return MongoConnection.connect(
            to: self.configuration.connectionURL.absoluteString,
            database: self.configuration.database,
            options: self.configuration.options,
            threadPool: threadPool,
            on: self.eventLoop
        )
    }
}
