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

    public func convert(_ fluent: DatabaseQuery) -> MongoCommand {

        let command: MongoCommand

        switch fluent.action {
        case .read:
            command = self.find(fluent)
        case .create:
            command = self.insert(fluent)
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

    private func insert(_ query: DatabaseQuery) -> MongoCommand {

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
