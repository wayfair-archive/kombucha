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

final class JSONValueTests: XCTestCase {
    func testDecodeArray() throws {
        let json = """
{ "fooKey": [true, 1] }
"""
        XCTAssertEqual(
            JSONValue.object(["fooKey": .array([.bool(true), .double(1)])]),
            try JSONDecoder().decode(
                JSONValue.self, from: json.data(using: .utf8)!)
        )
    }

    func testDecodeBool() throws {
        let json = """
{ "fooKey": true }
"""
        XCTAssertEqual(
            JSONValue.object(["fooKey": .bool(true)]),
            try JSONDecoder().decode(
                JSONValue.self, from: json.data(using: .utf8)!)
        )
    }

    func testDecodeDouble() throws {
        let json = """
{ "fooKey": 1.2345 }
"""
        XCTAssertEqual(
            JSONValue.object(["fooKey": .double(1.2345)]),
            try JSONDecoder().decode(
                JSONValue.self, from: json.data(using: .utf8)!)
        )
    }

    func testDecodeNull() throws {
        let json = """
{ "fooKey": null }
"""
        XCTAssertEqual(
            JSONValue.object(["fooKey": .null]),
            try JSONDecoder().decode(
                JSONValue.self, from: json.data(using: .utf8)!)
        )
    }

    func testDecodeString() throws {
        let json = """
{ "fooKey": "fooVal" }
"""
        XCTAssertEqual(
            JSONValue.object(["fooKey": .string("fooVal")]),
            try JSONDecoder().decode(
                JSONValue.self, from: json.data(using: .utf8)!)
        )
    }

    func testArrayRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .array(
                    [
                        .bool(true),
                        .double(1)
                    ]
                )
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testBoolRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .bool(true)
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testDoubleRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .double(1.2345)
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testNullRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .null
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testStringRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .string("fooVal")
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testComplexObjectRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .string("fooVal"),
                "bar": .null,
                "baz": .array(
                    [
                        .null,
                        .double(123),
                        .object(
                            [
                                "abc": .null,
                                "qqq": .object([:])
                            ]
                        )
                    ]
                ),
                "qux": .object(
                    [
                        "1": .null,
                        "2": .string("2"),
                        "3": .double(33333333)
                    ]
                )
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }

    func testLetsNestSomeObjectsLikeCrazyRoundTrip() throws {
        let expected: JSONValue = .object(
            [
                "foo": .object(
                    [
                        "bar": .object(
                            [
                                "baz": .object(
                                    [
                                        "qux": .null
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        )

        XCTAssertEqual(
            expected, try JSONDecoder().decode(
                JSONValue.self, from: JSONEncoder().encode(expected))
        )
    }
}
