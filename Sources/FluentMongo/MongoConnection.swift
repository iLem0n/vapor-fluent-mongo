//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import AsyncKit
import Logging
import MongoSwift

public final class MongoConnection: ConnectionPoolItem {

    public static func connect(
        to connectionString: String,
        database: String,
        options: ClientOptions? = nil,
        logger: Logger = .init(label: "vapor.fluent.mongo.connection"),
        threadPool: NIOThreadPool,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<MongoConnection> {

        let promise = eventLoop.makePromise(of: MongoConnection.self)

        threadPool.submit { _ in
            do {
                let connection = MongoConnection(
                    client: try MongoClient(connectionString, options: options),
                    database: database,
                    threadPool: threadPool,
                    logger: logger,
                    on: eventLoop
                )

                logger.debug("Connected to mongo db: \(database)")
                promise.succeed(connection)
            } catch {
                logger.error("Failed to connect to mongo db: \(database). \(error.localizedDescription)")
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    // MARK: Initialization

    init(
        client: MongoClient,
        database: String,
        threadPool: NIOThreadPool,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.client = client
        self.database = database
        self.threadPool = threadPool
        self.logger = logger
        self.eventLoop = eventLoop
    }

    // MARK: Accessing Attributes

    public let database: String

    public let eventLoop: EventLoop

    // MARK: Managing Connection

    private let client: MongoClient

    private let logger: Logger

    private let threadPool: NIOThreadPool

    // MARK: ConnectionPoolItem

    public private(set) var isClosed: Bool = false

    public func close() -> EventLoopFuture<Void> {

        let promise = self.eventLoop.makePromise(of: Void.self)

        self.threadPool.submit { state in
            self.client.close()
            self.eventLoop.submit {
                self.isClosed = true
            }.cascade(to: promise)
        }

        return promise.futureResult
    }
}
