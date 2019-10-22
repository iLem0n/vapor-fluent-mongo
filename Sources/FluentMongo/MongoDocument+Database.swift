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

extension Document: DatabaseRow {

    public func contains(field: String) -> Bool {
        return self.hasKey(field)
    }

    public func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T: Decodable {

        guard let driver = database.driver as? MongoDatabaseDriver else {
            throw DecodingError.typeMismatch(MongoDatabaseDriver.self, .init(codingPath: [], debugDescription: "Database.driver is not of type \"MongoDatabaseDriver\"."))
        }

        let decoder = try driver.decoder.decode(DecoderUnwrapper.self, from: self).decoder
        let container = try decoder.container(keyedBy: DatabaseRowCodingKey.self)

        return try container.decode(T.self, forKey: .init(field))
    }
}

extension Document {

    private struct DecoderUnwrapper: Decodable {

        let decoder: Decoder

        init(from decoder: Decoder) {
            self.decoder = decoder
        }
    }

    private struct DatabaseRowCodingKey: CodingKey {

        init(_ stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}
