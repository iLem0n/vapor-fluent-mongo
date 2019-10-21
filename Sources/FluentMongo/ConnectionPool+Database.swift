//
//  ConnectionPool+Database.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import AsyncKit

extension ConnectionPool: Database where Source.Connection: Database {

    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(schema) }
    }

    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(query, onOutput) }
    }

    public func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { (conn: Source.Connection) in
            return closure(conn)
        }
    }
}