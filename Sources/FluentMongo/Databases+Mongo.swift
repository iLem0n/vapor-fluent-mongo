//
//  Databases+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import AsyncKit
import FluentKit
import Logging

extension DatabaseID {
    public static var mongo: DatabaseID {
        return .init(string: "mongo")
    }
}

extension Databases {
    public mutating func mongo(
        configuration: MongoConfiguration,
        threadPool: NIOThreadPool,
        poolConfiguration: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .mongo,
        isDefault: Bool = true
    ) {
        let db = MongoConnectionSource(
            configuration: configuration,
            threadPool: threadPool,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}
