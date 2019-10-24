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

        var documents = [MongoDocument]()

        let fields = query.fields.map { self.field($0) }

        for input in query.input {
            var document = MongoDocument()
            for (field, value) in zip(fields, input) {
                document[field] = try self.value(value, using: encoder)
            }
            documents.append(document)
        }

        func defaultRow() -> [DatabaseRow] {
            // tanner: you should always return a row on create containing all the default values - if there are no default or db generated values, then just return an empty one
            return documents.count == 1 ? [Document()] : []
        }

        let collection = database.collection(self.query.schema)

        switch documents.count {
        case 1:
            guard let result = try collection.insertOne(documents.removeFirst()) else {
                return defaultRow()
            }

            return [result]
        default:
            let result = try collection.insertMany(documents)
            // TODO: Log result
            return defaultRow()
        }
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

    private func field(_ field: DatabaseQuery.Field) -> [String] {
        switch field {
        case .aggregate(let aggregate):
            fatalError()
        case .field(let path, let schema, let alias):
            return path
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
