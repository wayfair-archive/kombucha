//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

@testable import JSONValue
import XCTest

final class JSONIndexTests: XCTestCase {
    func testIndexIntoAnArray() {
        let jsonValue = JSONValue.array([
            .bool(true),
            .string("hello"),
            .double(3.0)
            ])
        XCTAssertEqual(
            JSONValue.string("hello"),
            jsonValue[.arrayIndex(1)]
        )
    }

    func testIndexIntoAnObject() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .array([]),
            "baz": .double(99.0)
            ])
        XCTAssertEqual(
            JSONValue.double(99.0),
            jsonValue[.objectIndex("baz")]
        )
    }

    func testIndexingIncorrectlyReturnsNil() {
        XCTAssertNil(
            JSONValue.null[.arrayIndex(99)]
        )
        XCTAssertNil(
            JSONValue.array([.bool(true)])[.arrayIndex(99)]
        )
        XCTAssertNil(
            JSONValue.object(["foo": .null])[.objectIndex("hi")]
        )
        XCTAssertNil(
            JSONValue.array([])[.objectIndex("ok")]
        )
        XCTAssertNil(
            JSONValue.object([:])[.arrayIndex(99)]
        )
    }

    func testIndexNowhereIntoAValue() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("baz")
            ])
        XCTAssertEqual(
            jsonValue,
            jsonValue[context: []]
        )
    }

    func testIndexOnceIntoAValue() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("baz")
            ])
        XCTAssertEqual(
            JSONValue.string("baz"),
            jsonValue[context: [.objectIndex("bar")]]
        )
    }

    func testIndexDeepIntoAValue() {
        let jsonValue = JSONValue.array([
            .bool(true),
            .array([
                .object([
                    "foo": .string("fooVal"),
                    "bar": .array([
                        .object([
                            "baz": .double(99),
                            "qux": .null
                            ])
                        ])
                    ])
                ])
            ])
        let jsonContext: JSONContext = [.arrayIndex(1), .arrayIndex(0), .objectIndex("bar"), .arrayIndex(0), .objectIndex("baz")]
        XCTAssertEqual(
            JSONValue.double(99),
            jsonValue[context: jsonContext]
        )
    }
}
