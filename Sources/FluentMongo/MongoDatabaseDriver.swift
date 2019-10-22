//
//  MongoDatabaseDriver.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import FluentKit
import MongoSwift

struct MongoDatabaseDriver {

    // MARK: Initialization

    public init(
        pool: ConnectionPool<MongoConnectionSource>,
        encoder: BSONEncoder = BSONEncoder(),
        decoder: BSONDecoder = BSONDecoder()
    ) {
        self.pool = pool
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: Accessing Attributes

    public let pool: ConnectionPool<MongoConnectionSource>

    let encoder: BSONEncoder

    let decoder: BSONDecoder
}

extension MongoDatabaseDriver: DatabaseDriver {

    public var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }

    func execute(query: DatabaseQuery, database: Database, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        fatalError()
    }

    func execute(schema: DatabaseSchema, database: Database) -> EventLoopFuture<Void> {
        fatalError()
    }

    func shutdown() {
        self.pool.shutdown()
    }
}
