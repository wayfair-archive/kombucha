import XCTest

import JSONCheckTests
import JSONValueTests
import KombuchaLibTests

var tests = [XCTestCaseEntry]()
tests += JSONCheckTests.__allTests()
tests += JSONValueTests.__allTests()
tests += KombuchaLibTests.__allTests()

XCTMain(tests)
