import XCTest

import TypeBuilderTests

var tests = [XCTestCaseEntry]()
tests += TypeBuilderTests.allTests()
tests += BuilderDecoderTests.allTests()
XCTMain(tests)
