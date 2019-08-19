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
import Prelude
import XCTest

final class JSONCheckTests: XCTestCase {
    func testCheckStructurePasses() {
        let referenceValue = JSONValue.bool(true)

        let results = JSONCheck.structure.run(
            .empty,
            referenceValue,
            JSONValue.bool(false)
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testCheckStructureFails() {
        let referenceValue = JSONValue.bool(true)

        let results = JSONCheck.structure.run(
            .empty,
            referenceValue,
            JSONValue.double(1.0)
        )
        XCTAssertEqual(1, results.count)

        XCTAssertTrue(results[0].message.contains("Types"))
        XCTAssertEqual([], results[0].context)
    }

    func testCheckStructureFailsWithProperContext() {
        let referenceValue = JSONValue.array([
            .object([
                "foo": .string("fooVal"),
                "bar": .double(99.0),
                "baz": .array([])
                ])
            ])

        let testValue = JSONValue.array([
            .object([
                "foo": .object([:]),
                "bar": .double(1)
                ])
            ])

        let results = JSONCheck.structure.run(.empty, referenceValue, testValue)
        XCTAssertEqual(2, results.count)

        // results can come back in any order, so it’s a little annoying to find the things we want to assert on here…
        guard let typesResult = results.first(where: { $0.message.contains("Types") }) else {
            XCTFail()
            return
        }

        XCTAssertEqual(
            [JSONIndex.arrayIndex(0), .objectIndex("foo")],
            typesResult.context
        )

        guard let doesNotExistResult = results.first(where: { $0.message.contains("does not exist") }) else {
            XCTFail()
            return
        }

        XCTAssertEqual(
            [JSONIndex.arrayIndex(0)],
            doesNotExistResult.context
        )
    }

    func testDefaultChecksTestArrayConsistencySucceeds() {
        let referenceValue = JSONValue.array([
            .bool(true)
            ])

        let testValue = JSONValue.array([
            .bool(false),
            .bool(true)
            ])

        let results = JSONCheck.arrayConsistency.run(.empty, referenceValue, testValue)
        XCTAssertTrue(results.isEmpty)
    }

    func testCheckArrayConsistencyFails() {
        let referenceValue = JSONValue.array([
            .bool(true)
            ])

        let testValue = JSONValue.array([
            .bool(false),
            .string("hello world")
            ])

        let results = JSONCheck.arrayConsistency.run(.empty, referenceValue, testValue)
        XCTAssertEqual(1, results.count)
        XCTAssertTrue(results[0].message.contains("Types"))
        XCTAssertEqual(
            [JSONIndex.arrayIndex(1)],
            results[0].context
        )
    }

    func testCheckStructureAndArraysSeveralErrorsAndWarnings() {
        let referenceValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .array([
                .double(9.0)
                ]),
            "baz": .string("bazVal")
            ])

        let testValue = JSONValue.object([
            "foo": .bool(false),
            "bar": .array([
                .bool(true),
                .string("barVal")
                ])
            ])

        let structureAsErrors = JSONCheck.structure.map(CheckResults.asErrors)
        let arrayConsistencyAsWarnings = JSONCheck.arrayConsistency.map(CheckResults.asWarnings)

        let results = (structureAsErrors <> arrayConsistencyAsWarnings).run(.empty, referenceValue, testValue)
        XCTAssertEqual(2, results.errors.count)
        XCTAssertTrue(results.infos.isEmpty)
        XCTAssertEqual(1, results.warnings.count)
    }

    func testCheckEmptyArraySucceeds() {
        let jsonValue = JSONValue.array([
            .bool(true),
            .array([
                .string("foo")
                ])
            ])

        XCTAssertTrue(JSONCheck.emptyArrays.run(.empty, .null, jsonValue).isEmpty)
    }

    func testCheckEmptyArrayFails() {
        let jsonValue = JSONValue.array([
            .array([]),
            .bool(true),
            .array([])
            ])

        XCTAssertEqual(2, JSONCheck.emptyArrays.run(.empty, .null, jsonValue).count)
    }

    func testCheckEmptyObjectSucceeds() {
        let jsonValue = JSONValue.array([
            .object([
                "foo": .string("9")
                ]),
            .bool(false),
            .array([
                .object([
                    "bar": .double(9.0)
                    ])
                ])
            ])

        XCTAssertTrue(JSONCheck.emptyObjects.run(.empty, .null, jsonValue).isEmpty)
    }

    func testCheckEmptyObjectFails() {
        let jsonValue = JSONValue.array([
            .object([
                "foo": .string("9"),
                "bar": .object([:])
                ]),
            .bool(false),
            .array([
                .object([
                    "baz": .double(9.0),
                    "qux": .object([:])
                    ]),
                .object([:])
                ])
            ])

        XCTAssertEqual(3, JSONCheck.emptyObjects.run(.empty, .null, jsonValue).count)
    }

    func testCheckStringBoolSucceeds() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .array([
                .bool(false)
                ])
            ])
        XCTAssertTrue(JSONCheck.stringBools.run(.empty, .null, jsonValue).isEmpty)
    }

    func testCheckStringBoolFails() {
        let jsonValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .array([
                .bool(false),
                .string("trUe")
                ]),
            "baz": .string("FALSE")
            ])
        XCTAssertEqual(2, JSONCheck.stringBools.run(.empty, .null, jsonValue).count)
    }

    func testCheckStringNumberSucceeds() {
        let jsonValue = JSONValue.array([
            .object([
                "foo": .object([
                    "bar": .object([
                        "baz": .string("9"),
                        "qux": .double(9.0)
                        ]),
                    "fribble": .string("12345678.99")
                    ])
                ])
            ])

        XCTAssertEqual(2, JSONCheck.stringNumbers.run(.empty, .null, jsonValue).count)
    }

    func testCheckFlagNewKeysFails() {
        let referenceValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello"),
            "baz": .array([
                .object([
                    "one": .bool(false)
                    ]),
                    .null
                ])
            ])

        let testValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello"),
            "baz": .array([
                .object([
                    "one": .bool(false),
                    "two": .array([])
                    ]),
                .null
                ]),
            "qux": .double(99.0)
            ])

        let results = JSONCheck.flagNewKeys.run(.empty, referenceValue, testValue)
        XCTAssertEqual(2, results.count)

        // results can come back in any order so we will be extremely lazy here and test with `contains(where:)`)
        XCTAssertTrue(results.map { $0.context }.contains(where: { $0 == [] }))
        XCTAssertTrue(results.map { $0.context }.contains(where: { $0 == [JSONIndex.objectIndex("baz"), .arrayIndex(0)] }))
    }

    func testCheckFlagNewKeysSucceeds() {
        let referenceValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello"),
            "baz": .array([
                .object([
                    "one": .bool(false)
                    ]),
                .null
                ])
            ])

        let testValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello"),
            "baz": .array([
                .object([
                    "one": .string("hello"),
                    ]),
                .null
                ]),
            ])

        let results = JSONCheck.flagNewKeys.run(.empty, referenceValue, testValue)
        XCTAssertTrue(results.isEmpty)
    }
    
    func testStrictEqualityTestSuccess() {
        let referenceValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello1"),
            "baz": .array([
                .object([
                    "one": .bool(false),
                    "two": .array([
                        .bool(true),
                        .string("hello2"),
                        .object([
                            "alpha": .string("test"),
                            "beta" : .bool(false),
                            "gamma": .null
                            ])
                        ])
                    ]),
                .null,
                .double(23)
                ])
            ])
        
        let results = JSONCheck.strictEquality.run(.empty, referenceValue, referenceValue)
        XCTAssert(results.isEmpty)
    }
    
    func testStrictEqualityTestFails() {
        let referenceValue = JSONValue.object([
            "foo": .bool(true),
            "bar": .string("hello1"),
            "baz": .array([
                .object([
                    "one": .bool(false),
                    "two": .array([
                        .bool(true),
                        .string("hello2"),
                        .object([
                            "alpha": .string("test"),
                            "beta" : .bool(false),
                            "gamma": .null
                            ]),
                        .array([.bool(true)])
                        ])
                    ]),
                .null,
                .double(23)
                ])
            ])
        
        let testValue = JSONValue.object([ // 1. missing key "foo"
            "bar": .string("bye"), // 2. hello1 != bye
            "new_key": .string("new_value"), // 3. a new key
            "baz": .array([
                .object([
                    "one": .object([ // 4. bool != object
                        "new_object": .bool(false)
                        ]),
                    "two": .array([
                        .bool(true),
                        .string("hello2"),
                        .object([
                            "alpha": .string("test2"), // 5. test != test2
                            "beta" : .bool(false),
                            "gamma": .string("test3"),  // 6. null != test3
                            "delta": .bool(false) // 7. new key
                            ]),
                        .array([.bool(true), .bool(true)]) // 8. array of diffrent size
                        ])
                    ]),
                .double(34), // 9. null != 34
                .double(12) // 10. 12 != 23
                ])
            ])
        
        let results = JSONCheck.strictEquality.run(.empty, referenceValue, testValue)
        XCTAssertEqual(results.count, 10)
    }
}
