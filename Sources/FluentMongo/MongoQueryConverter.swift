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

    public func convert(_ fluent: DatabaseQuery, using encoder: BSONEncoder) -> MongoCommand {

        let command: MongoCommand

        switch fluent.action {
        case .read:
            command = self.find(fluent)
        case .create:
            command = self.insert(fluent, using: encoder)
        case .update:
            command = self.update(fluent)
        case .delete:
            command = self.delete(fluent)
        case .custom(let any):
            fatalError()
            //return custom(any)
        }

        return command
    }
}

extension MongoQueryConverter {

    private func find(_ query: DatabaseQuery) -> MongoCommand {
        return MongoCommand()
    }

    private func insert(_ query: DatabaseQuery, using encoder: BSONEncoder) -> MongoCommand {

        let document: MongoDocument = ["hello": "world"]

        return [
            "insert": query.schema,
            "documents": [document]
        ]
    }

    private func update(_ query: DatabaseQuery) -> MongoCommand {
        return MongoCommand()
    }

    private func delete(_ query: DatabaseQuery) -> MongoCommand {
        return MongoCommand()
    }

    private func custom(_ query: DatabaseQuery) -> MongoCommand {
        return MongoCommand()
    }
}

extension MongoQueryConverter {

    private func value(_ value: DatabaseQuery.Value, using encoder: BSONEncoder) throws -> BSONValue {
        switch value {
        case .bind(let encodable):
            let wrappedData = ["value": encodable]
            let document: Document = try encoder.encode(wrappedData)

            return document["value"] ?? BSONNull()
        case .null:
            return BSONNull()
        case .array(let values):
            return try values.map { try self.value($0, using: encoder) }
        case .dictionary(let dict):
            let d = dict.mapValues { try self.value($0, using: encoder) }
            return SQLBind(DictValues(dict: dict))
        case .default:
            return SQLLiteral.default
        case .custom(let any):
            return custom(any)
        }
    }
}
