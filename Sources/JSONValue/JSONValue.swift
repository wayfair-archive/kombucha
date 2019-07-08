//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

public enum JSONValue {
    indirect case array([JSONValue])
    case bool(Bool)
    case double(Double)
    case null
    indirect case object([String: JSONValue])
    case string(String)
}

extension JSONValue: Equatable { }

extension JSONValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .null:
            try container.encodeNil()
        case .object(let objectValue):
            try container.encode(objectValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        }
    }
}

extension JSONValue: Decodable {
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        if let arrayValue = try? singleValueContainer.decode([JSONValue].self) {
            self = .array(arrayValue)
            return
        }
        if let boolValue = try? singleValueContainer.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        if let doubleValue = try? singleValueContainer.decode(Double.self) {
            self = .double(doubleValue)
            return
        }
        if let objectValue = try? singleValueContainer.decode([String: JSONValue].self) {
            self = .object(objectValue)
            return
        }
        if let stringValue = try? singleValueContainer.decode(String.self) {
            self = .string(stringValue)
            return
        }

        if singleValueContainer.decodeNil() {
            self = .null
            return
        }

        throw DecodingError.dataCorruptedError(
            in: singleValueContainer,
            debugDescription: "invalid JSON structure or the input was not JSON")
    }
}
