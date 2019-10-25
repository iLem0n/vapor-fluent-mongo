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
            results = try self.find(database)
        case .create:
            results = try self.insert(database)
        case .update:
            results = try self.update(database)
        case .delete:
            results = try self.delete(database)
        case .custom(let any):
            fatalError()
            //return custom(any)
        }

        return results
    }
}

extension MongoQueryConverter {

    private func find(_ database: MongoDatabase) throws -> [DatabaseRow] {
        return []
    }

    private func insert(_ database: MongoDatabase) throws -> [DatabaseRow] {

        var documents = [Document]()

        let fields = try self.query.fields.map { try $0.field().path }

        for input in self.query.input {
            var document = Document()
            for (field, value) in zip(fields, input) where !field.starts(with: ["id"]) {
                #warning("TODO: rename id to _id")
                document[field] = try self.bsonValue(value)
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
            // TODO: Log result
            #warning("TODO: Handle this correctly")
            return [["fluentID": 0] as Document]
        default:
            let result = try collection.insertMany(documents)
            // TODO: Log result
            return defaultRow()
        }
    }

    private func update(_ database: MongoDatabase) throws -> [DatabaseRow] {
        return []
    }

    private func delete(_ database: MongoDatabase) throws -> [DatabaseRow] {
        let collection = database.collection(self.query.schema)
        let filter = Document()//self.filter()
        if let result = try collection.deleteMany(filter) {
            #warning("TODO: Log")
        }

        return []
    }

    private func custom(_ database: MongoDatabase) throws -> [DatabaseRow] {
        return []
    }
}

extension MongoQueryConverter {

    private func bsonValue(_ value: DatabaseQuery.Value) throws -> BSONValue {
        switch value {
        case .bind(let encodable):
            return try self.encoder.encode(encodable)
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

    private func joins() throws -> [Document] {
        return try self.query.joins.map { join in
            switch join {
            case .join(let schema, let foreign, let local, let method):
                let collection = try schema.schema().name
                let lookup: Document = [
                    "$lookup": [
                        "from": collection,
                        "localField": try local.field().path.joined(separator: "."),
                        "foreignField": try foreign.field().path.joined(separator: "."),
                        "as": collection
                    ] as Document
                ]

                let unwind: Document = [
                    "$unwind": [
                        "path": "$" + collection,
                        "preserveNullAndEmptyArrays": method.isOuter
                    ] as Document
                ]

                return [lookup, unwind]

            case .custom(let value):
                fatalError()
            }
        }
    }

    private func filter() -> Document? {
        self.query.filters
        fatalError()
    }
}

extension MongoQueryConverter {

    private func aggregationPipeline() throws -> [Document] {
        var pipeline = [Document]()

        // Joins
        if !self.query.joins.isEmpty {
            pipeline.append(contentsOf: try self.joins())
        }

        // Filters
        if let filter = self.filter() {
            pipeline.append(["$match": filter])
        }

        return pipeline
    }
}
