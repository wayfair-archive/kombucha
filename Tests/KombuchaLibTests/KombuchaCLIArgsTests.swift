//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

@testable import KombuchaLib
import XCTest

private let jsonDecoder = JSONDecoder()

final class KombuchaCLIArgsTests: XCTestCase {
    func testEmptyArgsNoThrows() {
        XCTAssertNoThrow(
            try KombuchaCLIArgs(parsingArgs: [])
        )
    }

    func testParseConfigurationParamDefault() throws {
        let args = try KombuchaCLIArgs(parsingArgs: [])
        XCTAssertEqual(
            URL(fileURLWithPath: "./kombucha.json"),
            args.configuration.value
        )
    }

    func testParseConfigurationParam() throws {
        let args = try KombuchaCLIArgs(parsingArgs: ["foo.bar"])
        XCTAssertEqual(
            URL(fileURLWithPath: "foo.bar"),
            args.configuration.value
        )
    }

    func testParsePrintErrorsOnlyParamDefault() throws {
        let args = try KombuchaCLIArgs(parsingArgs: [])
        XCTAssertEqual(
            false,
            args.printErrorsOnly
        )
    }

    func testParseSnapshotsURLDefaultAlongsideConfig() throws {
        let args = try KombuchaCLIArgs(parsingArgs: ["/foo/bar.baz"])
        XCTAssertEqual(
            URL(fileURLWithPath: "/foo/__Snapshots__/"),
            args.snapshotsURL.value
        )
    }

    func testParseWorkURLDefaultAlongsideConfig() throws {
        let args = try KombuchaCLIArgs(parsingArgs: ["/foo/bar/baz.qux"])
        XCTAssertEqual(
            URL(fileURLWithPath: "/foo/bar/__Work__/"),
            args.workURL.value
        )
    }
}
