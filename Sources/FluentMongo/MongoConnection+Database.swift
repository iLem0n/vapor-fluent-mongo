//
//  MongoConnection+Database.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension MongoConnection: Database {

    public func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }

    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        fatalError()
        /*
        let sql = SQLQueryConverter(delegate: MySQLConverterDelegate()).convert(query)
        var serializer = SQLSerializer(dialect: MySQLDialect())
        sql.serialize(to: &serializer)
        let binds = serializer.binds.map { encodable in
            return try! MySQLDataEncoder().encode(encodable)
        }
        return self.query(serializer.sql, binds, onRow: { row in
            try onOutput(row)
        }, onMetadata: { metadata in
            let row = LastInsertRow(metadata: metadata)
            try onOutput(row)
        })
        */
    }

    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        fatalError()
        /*
        let sql = SQLSchemaConverter(delegate: MySQLConverterDelegate()).convert(schema)
        return self.execute(sql: sql) { row in
            fatalError("unexpected output")
        }*/
    }
}
/*
struct LastInsertRow: DatabaseOutput {
    var description: String {
        return "\(self.metadata)"
    }

    let metadata: MySQLQueryMetadata

    func contains(field: String) -> Bool {
        return field == "fluentID"
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        switch field {
        case "fluentID":
            if T.self is Int.Type {
                return Int(self.metadata.lastInsertID!) as! T
            } else {
                fatalError()
            }
        default: throw FluentError.missingField(name: field)
        }
    }
}
*/
