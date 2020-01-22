import XCTest
@testable import TypeBuilder

final class TypeBuilderTests: XCTestCase {

    struct MyStruct: Codable, Reflectable {
        let text: String?
        let number: Int
    }

    func testSimpleProperties() {
        var builder = Builder<MyStruct>()
        builder[\.text] = "String"
        builder[\.number] = 111

        XCTAssertEqual(builder[\.text], "String")
        XCTAssertEqual(builder[\.number], 111)
    }

    func testWrongTypesAccess() {
        var builder = Builder<MyStruct>()
        // Throw error if value didn't set
        XCTAssertThrowsError(try builder.value(for: \.text))
        XCTAssertThrowsError(try builder.value(for: \.number))
        builder[\.text] = nil
        builder[\.number] = 2
        // Do not throw if we set nil for optional
        XCTAssertNoThrow(try builder.value(for: \.text))
        XCTAssertNoThrow(try builder.value(for: \.number))

        XCTAssertNil(builder[\.text])
        XCTAssertEqual(builder[\.number], 2)
    }

    static var allTests = [
        ("testSimpleProperties", testSimpleProperties),
        ("testWrongTypesAccess", testWrongTypesAccess)
    ]
}
