//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import MongoSwift

public final class MongoConnection: ConnectionPoolItem {

    public static func connect(
        to connectionString: String,
        database: String,
        options: ClientOptions? = nil,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<MongoConnection> {

        return eventLoop.submit {
            MongoConnection(
                client: try MongoClient(connectionString, options: options),
                database: database,
                on: eventLoop
            )
        }
    }
    // MARK: Initialization

    init(
        client: MongoClient,
        database: String,
        on eventLoop: EventLoop
    ) {
        self.client = client
        self.database = database
        self.eventLoop = eventLoop
    }

    // MARK: Accessing Attributes

    public let database: String

    public let eventLoop: EventLoop

    // MARK: Managing Connection

    private let client: MongoClient

    // MARK: ConnectionPoolItem

    public private(set) var isClosed: Bool = false

    public func close() -> EventLoopFuture<Void> {
        return self.eventLoop.submit {
            self.client.close()
            self.isClosed = true
        }
    }
}
