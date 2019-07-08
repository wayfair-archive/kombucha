//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

@testable import JSONCheck
import JSONValue
import XCTest

final class JSONValueAndPreludeTests: XCTestCase {
    func testJSONValueFoldOneLevel() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .double(1.0),
            "baz": .null,
            "qux": .string("hello")
            ])
        XCTAssertEqual(
            // sort the arrays here because there is no specific iteration order for the dictionary inside `JSONValue`
            ["true", "1.0", "null", "hello"].sorted(),
            jsonValue.fold(
                context: .empty,
                boolCase: { _, bool in ["\(bool)"] },
                doubleCase: { _, double in ["\(double)"] },
                nullCase: { _ in ["null"] },
                stringCase: { _, string in [string] }
                ).sorted()
        )
    }

    func testJSONValueFoldNested() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .double(1.0),
            "baz": .object([
                "1": .string("a"),
                "2": .array([
                    .string("q"),
                    .bool(false),
                    .double(99.0)
                    ]),
                "3": .null
                ]),
            "qux": .string("hello")
            ])
        XCTAssertEqual(
            // sort the arrays here because there is no specific iteration order for the dictionary inside `JSONValue`
            ["true", "1.0", "a", "q", "false", "99.0", "null", "hello"].sorted(),
            jsonValue.fold(
                context: .empty,
                boolCase: { _, bool in ["\(bool)"] },
                doubleCase: { _, double in ["\(double)"] },
                nullCase: { _ in ["null"] },
                stringCase: { _, string in [string] }
                ).sorted()
        )
    }
}
