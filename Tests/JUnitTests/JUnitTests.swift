//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//
@testable import JUnit

import XCTest

final class JUnitTest: XCTestCase {
    
    func testCreation() {
        let report = JUnit.Report.new()
            .set(version: "1.0", characterEncoding: "UTF-8")
            .set(suites:
                JUnit.TestSuites.Element.new().set(suites: [
                    JUnit.TestSuite.Element.new().set(testCases: [
                        JUnit.TestCase.Element.new().set(attributes: [
                            JUnit.TestCase.Attribute.id(value: UUID.init(uuidString: "D60AD064-2BA3-461C-A278-A8A570865281")!),
                            JUnit.TestCase.Attribute.name(text: "1-1"),
                            JUnit.TestCase.Attribute.time(value: 1.1)
                            ]),
                        JUnit.TestCase.Element.new().set(attributes: [
                            JUnit.TestCase.Attribute.id(value: UUID.init(uuidString: "0E10E188-832C-4FAF-B404-DC35294C798B")!),
                            JUnit.TestCase.Attribute.name(text: "1-2"),
                            JUnit.TestCase.Attribute.time(value: 1.2)
                            ]).set(failures: [
                                JUnit.Failure.Element.new(withText: "A description of the failure").set(attributes: [
                                    JUnit.Failure.Attribute.message(text: "a failed test"),
                                    JUnit.Failure.Attribute.type(text: "warning")
                                    ])
                                ])
                        ]).set(attributes: [
                            JUnit.TestSuite.Attribute.id(value: UUID.init(uuidString: "82CB4491-ACEE-4502-9673-AFB1DD9E70F4")!),
                            JUnit.TestSuite.Attribute.name(text: "Test name for TestSuite 1"),
                            JUnit.TestSuite.Attribute.tests(number: 12),
                            JUnit.TestSuite.Attribute.failures(number: 3),
                            JUnit.TestSuite.Attribute.time(value: 10.78)
                            ]),
                    JUnit.TestSuite.Element.new().set(testCases: [
                        JUnit.TestCase.Element.new().set(attributes: [
                            JUnit.TestCase.Attribute.id(value: UUID.init(uuidString: "D60AD064-2BA3-461C-A278-A8A570865281")!),
                            JUnit.TestCase.Attribute.name(text: "2-1"),
                            JUnit.TestCase.Attribute.time(value: 2.1)
                            ]),
                        JUnit.TestCase.Element.new().set(attributes: [
                            JUnit.TestCase.Attribute.id(value: UUID.init(uuidString: "1531DC00-832E-45D9-9B04-9893D3A93B29")!),
                            JUnit.TestCase.Attribute.name(text: "2-1"),
                            JUnit.TestCase.Attribute.time(value: 2.1)
                            ])
                        ]).set(attributes: [
                            JUnit.TestSuite.Attribute.id(value: UUID.init(uuidString: "BB495D15-CBD6-45F1-898E-61A1B917551A")!),
                            JUnit.TestSuite.Attribute.name(text: "Test name for TestSuite 2"),
                            JUnit.TestSuite.Attribute.tests(number: 22),
                            JUnit.TestSuite.Attribute.failures(number: 4),
                            JUnit.TestSuite.Attribute.time(value: 113)
                            ]),
                    ]).set(attributes: [
                        JUnit.TestSuites.Attribute.id(value: UUID.init(uuidString: "6C142A1F-70C6-4ACB-9968-EEB61CA6C850")!),
                        JUnit.TestSuites.Attribute.name(text: "Test name for TestSuites"),
                        JUnit.TestSuites.Attribute.tests(number: 34),
                        JUnit.TestSuites.Attribute.failures(number: 23),
                        JUnit.TestSuites.Attribute.time(value: 123.78)
                        ])
        )
        
        XCTAssertEqual(
            report.create() , """
<?xml version="1.0" encoding="UTF-8"?><testsuites id="6C142A1F-70C6-4ACB-9968-EEB61CA6C850" name="Test name for TestSuites" tests="34" failures="23" time="123.78"><testsuite id="82CB4491-ACEE-4502-9673-AFB1DD9E70F4" name="Test name for TestSuite 1" tests="12" failures="3" time="10.78"><testcase id="D60AD064-2BA3-461C-A278-A8A570865281" name="1-1" time="1.1"></testcase><testcase id="0E10E188-832C-4FAF-B404-DC35294C798B" name="1-2" time="1.2"><failure message="a failed test" type="warning">A description of the failure</failure></testcase></testsuite><testsuite id="BB495D15-CBD6-45F1-898E-61A1B917551A" name="Test name for TestSuite 2" tests="22" failures="4" time="113.0"><testcase id="D60AD064-2BA3-461C-A278-A8A570865281" name="2-1" time="2.1"></testcase><testcase id="1531DC00-832E-45D9-9B04-9893D3A93B29" name="2-1" time="2.1"></testcase></testsuite></testsuites>
"""
        )
    }
}
