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

private extension CheckResult {
    func assert(
        file: StaticString = #file,
        line: UInt = #line,
        messageAppearsAt context: JSONContext,
        satisfying check: ((String) -> Void)? = nil) {
        guard let myRec = self[context], let myMessage = myRec.first else {
            XCTFail("expected a message generated at the location \(context)", file: file, line: line)
            return
        }
        check?(myMessage)
    }
}

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

        guard let firstRec = results[.root], let firstResult = firstRec.first else {
            XCTFail("expected exactly one result at the root of the JSON")
            return
        }
        XCTAssertTrue(firstResult.contains("Types"))
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

        guard let typesRec = results[[JSONIndex.arrayIndex(0), .objectIndex("foo")]], let typesMessage = typesRec.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(typesMessage.contains("Types"))

        guard let doesNotExistRec = results[[JSONIndex.arrayIndex(0)]], let doesNotExistMessage = doesNotExistRec.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(doesNotExistMessage.contains("does not exist"))
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

        guard let typesRec = results[[JSONIndex.arrayIndex(1)]], let typesMessage = typesRec.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(typesMessage.contains("Types"))
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

        let structureAsErrors = JSONCheck.structure.map(mapToErrors)
        let arrayConsistencyAsWarnings = JSONCheck.arrayConsistency.map(mapToWarnings)

        let results = (structureAsErrors <> arrayConsistencyAsWarnings).run(.empty, referenceValue, testValue)

        guard let typesRec1 = results.errors[[JSONIndex.objectIndex("bar"), .arrayIndex(0)]], let typesMessage1 = typesRec1.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(typesMessage1.contains("Types"))

        guard let typesRec2 = results.errors[.root], let typesMessage2 = typesRec2.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(typesMessage2.contains("The key baz"))

        XCTAssertTrue(results.infos.isEmpty)

        guard let arraysRec = results.warnings[[JSONIndex.objectIndex("bar"), .arrayIndex(1)]], let arraysMessage = arraysRec.first else {
            XCTFail("expected a message generated at the above JSON location")
            return
        }
        XCTAssertTrue(arraysMessage.contains("Types"))
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

        let results = JSONCheck.emptyArrays.run(.empty, .null, jsonValue)
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(0)])
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(2)])
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

        let results = JSONCheck.emptyObjects.run(.empty, .null, jsonValue)
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(0), .objectIndex("bar")])
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(2), .arrayIndex(0), .objectIndex("qux")])
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(2), .arrayIndex(1)])
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
        let results = JSONCheck.stringBools.run(.empty, .null, jsonValue)

        guard let firstResults = results[[JSONIndex.objectIndex("bar"), .arrayIndex(1)]], firstResults.count == 1 else {
            XCTFail("expected a single result at the above location")
            return
        }
        XCTAssertTrue(firstResults.first!.contains("bool"))

        guard let secondResults = results[[JSONIndex.objectIndex("baz")]], secondResults.count == 1 else {
            XCTFail("expected a single result at the above location")
            return
        }
        XCTAssertTrue(secondResults.first!.contains("bool"))
    }

    func testCheckStringNumberFails() {
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

        let results = JSONCheck.stringNumbers.run(.empty, .null, jsonValue)
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(0), .objectIndex("foo"), .objectIndex("bar"), .objectIndex("baz")]) {
            XCTAssertTrue($0.contains("9"))
        }
        results.assert(messageAppearsAt: [JSONIndex.arrayIndex(0), .objectIndex("foo"), .objectIndex("fribble")]) {
            XCTAssertTrue($0.contains("12345678.99"))
        }
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
        results.assert(messageAppearsAt: .root) {
            XCTAssertTrue($0.contains("qux"))
        }
        results.assert(messageAppearsAt: [JSONIndex.objectIndex("baz"), .arrayIndex(0)]) {
            XCTAssertTrue($0.contains("two"))
        }
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

        XCTAssertTrue(JSONCheck.flagNewKeys.run(.empty, referenceValue, testValue).values.isEmpty)
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
        XCTAssertEqual(results.values.flatMap(id).count, 10)
    }
}
