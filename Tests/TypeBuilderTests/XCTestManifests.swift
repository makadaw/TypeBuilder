import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BuilderDecoderTests.allTests),
        testCase(TypeBuilderTests.allTests),
    ]
}
#endif
