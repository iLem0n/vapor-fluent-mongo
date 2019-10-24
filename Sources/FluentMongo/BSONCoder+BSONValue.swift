//
//  BSONCoder+BSONValue.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 24/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift

extension BSONDecoder {

    public func decode<T: Decodable>(_ type: T.Type, from document: Document, forKey key: String) throws -> T {
        let decoder = try self.decode(DecoderUnwrapper.self, from: document).decoder
        let container = try decoder.container(keyedBy: DecoderUnwrapperRowCodingKey.self)

        return try container.decode(T.self, forKey: .init(key))
    }
}

extension BSONDecoder {

    private struct DecoderUnwrapper: Decodable {

        let decoder: Decoder

        init(from decoder: Decoder) {
            self.decoder = decoder
        }
    }

    private struct DecoderUnwrapperRowCodingKey: CodingKey {

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
