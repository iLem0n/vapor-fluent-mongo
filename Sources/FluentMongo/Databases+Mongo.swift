//
//  Databases+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import AsyncKit

extension DatabaseID {
    public static var mongo: DatabaseID {
        return .init(string: "mongo")
    }
}

extension Databases {
    public mutating func mongo(
        configuration: MongoConfiguration,
        poolConfiguration: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .mongo,
        isDefault: Bool = true
    ) {
        let db = MongoConnectionSource(
            configuration: configuration,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}
