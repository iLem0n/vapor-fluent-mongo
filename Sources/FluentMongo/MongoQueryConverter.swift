//
//  MongoQueryConverter.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

public struct MongoQueryConverter {

    public init(_ query: DatabaseQuery, using encoder: BSONEncoder) {
        self.query = query
        self.encoder = encoder
    }

    private let query: DatabaseQuery
    
    private let encoder: BSONEncoder

    public func convert(_ database: MongoDatabase) throws -> [DatabaseRow] {

        let results: [DatabaseRow]

        switch self.query.action {
        case .read:
            results = self.find(database)
        case .create:
            results = try self.insert(database)
        case .update:
            results = self.update(database)
        case .delete:
            results = self.delete(database)
        case .custom(let any):
            fatalError()
            //return custom(any)
        }

        return results
    }
}

extension MongoQueryConverter {

    private func find(_ database: MongoDatabase) -> [DatabaseRow] {
        return []
    }

    private func insert(_ database: MongoDatabase) throws -> [DatabaseRow] {

        var document = MongoDocument()

        for (field, input) in zip(query.fields, query.input) {
            let field = self.field(field)
            let value = try self.value(input.first!, using: encoder)
            document[field] = value
        }

        let collection = database.collection(self.query.schema)

        guard let result = try collection.insertOne(document) else {
            return []
        }

        return [result]
    }

    private func update(_ database: MongoDatabase) -> [DatabaseRow] {
        return []
    }

    private func delete(_ database: MongoDatabase) -> [DatabaseRow] {
        return []
    }

    private func custom(_ database: MongoDatabase) -> [DatabaseRow] {
        return []
    }
}

extension MongoQueryConverter {

    private struct AnyEncodable: Encodable {
        public let encodable: Encodable

        public init(_ encodable: Encodable) {
            self.encodable = encodable
        }

        public func encode(to encoder: Encoder) throws {
            try self.encodable.encode(to: encoder)
        }
    }

    private func field(_ field: DatabaseQuery.Field) -> String {
        switch field {
        case .aggregate(let aggregate):
            fatalError()
        case .field(let path, let schema, let alias):
            return path.first!
        case .custom(let value):
            fatalError()
        }
    }

    private func value(_ value: DatabaseQuery.Value, using encoder: BSONEncoder) throws -> BSONValue {
        switch value {
        case .bind(let encodable):
            let wrappedData = ["value": AnyEncodable(encodable)]
            let document: Document = try encoder.encode(wrappedData)

            return document["value"] ?? BSONNull()
        case .null:
            return BSONNull()
        case .array(let values):
            fatalError() // only used when filtering
        case .dictionary(let dict):
            fatalError() // never used
        case .default:
            return BSONNull() // ignore if not _id
        case .custom(let value as BSONValue):
            return value
        case .custom:
            fatalError() // not supported
        }
    }
}
