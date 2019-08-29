import XCTest

import JSONCheckTests
import JSONValueTests
import JUnitTests
import KombuchaLibTests

var tests = [XCTestCaseEntry]()
tests += JSONCheckTests.__allTests()
tests += JSONValueTests.__allTests()
tests += JUnitTests.__allTests()
tests += KombuchaLibTests.__allTests()

XCTMain(tests)
