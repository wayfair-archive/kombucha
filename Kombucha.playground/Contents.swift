//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// Kombucha APIs quick start!!

import JSONValue

// a `JSONValue` is an enum that represents any kind of JSON structure
let jsonValue = JSONValue.array([
    .bool(true),
    .object([
        "foo": .string("hello"),
        "bar": .double(99.0),
        "baz": .array([])
        ])
    ])

// we can encode one to a string, just like with any `Encodable` type
import Foundation
let encoded = try JSONEncoder().encode(jsonValue)
String(data: encoded, encoding: .utf8)!

// a `JSONIndex` represents a location in a `JSONValue` …
let index = JSONIndex.arrayIndex(0)
jsonValue[index]

// a `JSONContext` is just an array of `JSONIndex`es. It represents a “path” into a JSON structure …
let jsonContext: JSONContext = [.arrayIndex(1), .objectIndex("bar")]
jsonValue[context: jsonContext]

import JSONCheck
import Prelude
// a `JSONCheck` represents a function that walks over some `JSONValue`s and produces some result. This check looks for empty arrays in the right-hand-side `JSONValue` it is passed:
let result = JSONCheck.emptyArrays.run(.empty, .null, jsonValue)
// you get back a dictionary where the keys are `JSONContext`s (locations in the JSON) …
let first = result.keys.first!
// and the values are the errors or results that the check found at those locations:
result[first]!

// the real benefit of a `JSONCheck` is that you can use them to compare two `JSONValue`s side-by-side.
// here is a `JSONValue` that is almost like the one we started with, but has a different type at its 0’th index:
let myValue = JSONValue.array([
    .string("different"),
    .object([
        "foo": .string("hello"),
        "bar": .double(99.0),
        "baz": .array([])
        ])
    ])

// this `JSONCheck` will find that discrepancy for us…
let result2 = JSONCheck.structure.run(.empty, jsonValue, myValue)
let first2 = result2.keys.first!
result2[first2]!

// conclusively testing JSON *arrays* in this way can be kinda tricky, but for JSON *objects*, we can perform this check nested arbitrarily deep!
let referenceValue = JSONValue.object([
    "foo": .object([
        "bar": .object([
            "baz": .object([
                "one": .bool(true),
                "two": .string("hello")
                ])
            ])
        ])
    ])
let testValue = JSONValue.object([
    "foo": .object([
        "bar": .object([
            "baz": .object([
                "one": .double(99.0),
                "two": .bool(false)
                ])
            ])
        ])
    ])
let result3 = JSONCheck.structure.run(.empty, referenceValue, testValue)
for key in result3.keys {
    print("\(key.prettyPrinted): \(result3[key]!)")
}

let total: (JSONF<Double>) -> Double = { json in
    switch json {
    case .array(let arrayValue):
        return arrayValue.reduce(0, +)
    case .bool(let boolValue):
        return 0
    case .double(let doubleValue):
        return doubleValue
    case .null:
        return 0
    case .object(let objectValue):
        return objectValue.values.reduce(0, +)
    case .string(let stringValue):
        return 0
    }
}
cata(total) <| .fixJ(testValue)

let append: (JSONF<String>) -> String = { json in
    switch json {
    case .array(let arrayValue):
        return arrayValue.reduce("", +)
    case .bool:
        return ""
    case .double:
        return ""
    case .null:
        return ""
    case .object(let objectValue):
        return objectValue.values.reduce("", +)
    case .string(let stringValue):
        return stringValue
    }
}
cata(append) <| .fixJ(myValue)

let appendM = algebra(
    array: { $0.reduce("", +) },
    object: { $0.values.reduce("", +) },
    string: { $0 }
)
cata(appendM) <| .fixJ(myValue)
