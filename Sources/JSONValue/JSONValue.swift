//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

/// `JSONF` is a representation of JSON with each recursive position (where normally there could be more nested JSON) replaced by the type parameter `A`. We’ll make this concrete later by combining it with `InJ`. Writing this this way allows `JSONF` to be a functor (ie. we can write `map(_:)` for it)
public enum JSONF<A> {
    case array([A])
    case bool(Bool)
    case double(Double)
    case null
    case object([String: A])
    case string(String)

    /// `map` a `JSONF`. Pass a function `(A) -> B` to convert all the values at the recursive positions in `self` into type `B`. Values that don’t represent recursive positions in the JSON (eg. `case .bool(Bool)`) are not transformed
    /// - Parameter transform: a from `A` to `B`
    public func map<B>(_ transform: (A) -> B) -> JSONF<B> {
        switch self {
        case .array(let arrayValue):
            return .array(arrayValue.map(transform))
        case .bool(let boolValue):
            return .bool(boolValue)
        case .double(let doubleValue):
            return .double(doubleValue)
        case .null:
            return .null
        case .object(let objectValue):
            return .object(objectValue.mapValues(transform))
        case .string(let stringValue):
            return .string(stringValue)
        }
    }

    public typealias Algebra = (JSONF) -> A
}

// MARK: - Equatable

extension JSONF: Equatable where A: Equatable { }

// MARK: - Codable

extension JSONF: Encodable where A == InJ {
    /// encode a `JSONF<InJ>` by leaving out the `InJ` part. We don’t need it in the JSON at all
    /// - Parameter encoder: an `Encoder`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let arrayValue):
            try container.encode(
                arrayValue.map { $0.outJ }
            )
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .null:
            try container.encodeNil()
        case .object(let objectValue):
            try container.encode(
                objectValue.mapValues { $0.outJ }
            )
        case .string(let stringValue):
            try container.encode(stringValue)
        }
    }
}

extension JSONF: Decodable where A == InJ {
    /// decode a `JSONF<InJ>` by inserting the `InJ`s where needed. They won’t have any representation in the JSON at all
    /// - Parameter decoder: a `Decoder`
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arrayValue = try? container.decode([JSONF<InJ>].self) {
            self = .array(
                arrayValue.map(InJ.fixJ)
            )
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }
        if let objectValue = try? container.decode([String: JSONF<InJ>].self) {
            self = .object(
                objectValue.mapValues(InJ.fixJ)
            )
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "invalid JSON structure or the input was not JSON"
        )
    }
}

public enum InJ: Equatable {
    indirect case fixJ(JSONF<InJ>)
}

public extension InJ {
    var outJ: JSONF<InJ> {
        switch self {
        case .fixJ(let jsonF):
            return jsonF
        }
    }
}

public extension InJ {
    static var null: InJ {
        return .fixJ(.null)
    }

    static func array(_ arrayValue: [InJ]) -> InJ {
        return .fixJ(.array(arrayValue))
    }

    static func bool(_ boolValue: Bool) -> InJ {
        return .fixJ(.bool(boolValue))
    }

    static func double(_ doubleValue: Double) -> InJ {
        return .fixJ(.double(doubleValue))
    }

    static func object(_ objectValue: [String: InJ]) -> InJ {
        return .fixJ(.object(objectValue))
    }

    static func string(_ stringValue: String) -> InJ {
        return .fixJ(.string(stringValue))
    }
}

import Prelude

public func cata<A>(_ algebra: @escaping JSONF<A>.Algebra) -> (InJ) -> A {
    return { $0.outJ.map(cata <| algebra) |> algebra }
}

public func algebra<M: Monoid>(
    array: @escaping ([M]) -> M = { _ in .empty },
    bool: @escaping (Bool) -> M = { _ in .empty },
    double: @escaping (Double) -> M = { _ in .empty },
    null: @escaping @autoclosure () -> M = .empty,
    object: @escaping ([String: M]) -> M = { _ in .empty },
    string: @escaping (String) -> M = { _ in .empty }) -> JSONF<M>.Algebra {
    return { json in
        switch json {
        case .array(let arrayValue):
            return array(arrayValue)
        case .bool(let boolValue):
            return bool(boolValue)
        case .double(let doubleValue):
            return double(doubleValue)
        case .null:
            return null()
        case .object(let objectValue):
            return object(objectValue)
        case .string(let stringValue):
            return string(stringValue)
        }
    }
}

public typealias JSONValue = JSONF<InJ>
