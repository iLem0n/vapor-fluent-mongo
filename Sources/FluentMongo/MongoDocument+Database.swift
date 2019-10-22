//
//  MongoDocument+Database.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

public typealias MongoDocument = Document

extension Document: DatabaseOutput {

    public func contains(field: String) -> Bool {
        return self.hasKey(field)
    }

    public func decode<T>(field: String, as type: T.Type) throws -> T where T: Decodable {
        fatalError()
    }
}
