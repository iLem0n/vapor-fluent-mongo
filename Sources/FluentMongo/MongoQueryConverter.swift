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
        let filter = try self.filter(database)
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
            return try values.map { try self.bsonValue($0) }
        case .default:
            return BSONNull() // ignore if not _id
        case .custom(let value as BSONValue):
            return value
        case .custom:
            fatalError() // not supported
        case .dictionary(let dict):
            fatalError() // never used
        }
    }

    private func `operator`(from method: DatabaseQuery.Filter.Method) -> String {
        switch method {
        case .equality(let inverse):
            return inverse ? "$ne" : "$eq"
        case .order(let inverse, let equality):
            switch (inverse, equality) {
            case (true, true):
                return "$lte"
            case (true, false):
                return "$lt"
            case (false, true):
                return "$gte"
            case (false, false):
                return "$gt"
            }
        case .subset(let inverse):
            return inverse ? "$nin" : "$in"
        case .contains(let inverse, let location):
            #warning("TODO: implement this")
            fatalError()
        case .custom(let value as String):
            return value
        default:
            #warning("TODO: implement this")
            fatalError() // not supported
        }
    }
}

extension MongoQueryConverter {

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

    private func match() throws -> Document? {

        guard !self.query.filters.isEmpty else {
            return nil
        }

        return try self.query.filters.reduce(into: Document()) { document, filter in

            // Build
            switch filter {
            case .value(let field, let method, let value):
                #warning("TODO: check if we need path or pathWithNamespace - related to byRemovingKeysPrefix")
                let pathWithNamespace = try field.field()/*pathWithNamespace*/.path.joined(separator: ".")
                let op = self.operator(from: method)
                let value = try self.bsonValue(value)
                document[pathWithNamespace] = [op: value] as Document
            case .field(let lhs, let method, let rhs):
                fatalError()
            case .group(let filters, let relation):
                fatalError()
            case .custom(let document as Document):
                fatalError()
            default:
                break
            }

            // Apply
            /*
            let filterByRemovingRootNamespace = filter.byRemovingKeysPrefix(query.collection)

            switch query.filter {
            case .some(let document):
                query.filter = [query.defaultFilterRelation.rawValue: [document, filterByRemovingRootNamespace]]
            case .none:
                query.filter = filterByRemovingRootNamespace
            }
             */
        }
    }

    private func projection() -> Document? {
        var projection = Document()

        for field in self.query.fields {

            let key: String

            switch field {
            case .field(let path, let schema, let alias):
                let path = self.query.schema == schema
                    ? path
                    : DatabaseQuery.Field.QueryField(path: path, schema: schema, alias: alias).pathWithNamespace
                key = path.joined(separator: ".")
            case .custom(let value as String):
                key = value
            default:
                continue
            }

            projection[key] = true
        }

        guard !projection.isEmpty else {
            return nil
        }

        projection["_id"] = true

        return projection
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
        if let match = try self.match() {
            pipeline.append(["$match": match])
        }

        // Projection
        if let projection = self.projection() {
            pipeline.append(["$project": projection])
        }

        return pipeline
    }

    private func filter(_ database: MongoDatabase) throws -> Document {

        guard !self.query.filters.isEmpty else {
            return [:]
        }

        var pipeline = try self.aggregationPipeline()
        pipeline.append(["$project": ["_id": true] as Document])

        let cursor = try database.collection(self.query.schema).aggregate(pipeline)
        let identifiers = cursor.compactMap { $0["_id"] }

        return ["_id": ["$in": identifiers] as Document]
    }
}
