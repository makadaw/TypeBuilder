import XCTest
@testable import TypeBuilder

final class TypeBuilderTests: XCTestCase {

    struct MyStruct: Buildable {
        let text: String?
        var number: Int
    }

    struct NestedLevel: Buildable {
        let second_nested: MyStruct
    }

    struct ParentStruct: Buildable {
        let nested: NestedLevel
    }

    func testDirectProperties() {
        let builder = Builder<MyStruct>()
        builder.number = 123
        builder.text = "Text"

        XCTAssertEqual(builder.number, 123)
        XCTAssertEqual(builder.text, "Text")
    }

    func testNestedProperties() {
        let builder = Builder<ParentStruct>()

        builder.nested.second_nested.number = 10
        builder.nested.second_nested.text = "Text"

        XCTAssertNotNil(builder.nested.second_nested, "keyPath that point to not ReflectionDecodable need to return a lens")
        XCTAssertEqual(builder.nested.second_nested.number, 10, "keyPath that point to ReflectionDecodable need to return a value")
        XCTAssertEqual(builder.nested.second_nested.text, "Text")
    }

    func testNilProperties() {
        let builder = Builder<MyStruct>()

        // Set optional value
        builder.text = "text"
        XCTAssertEqual(builder.text, "text")

        // Reset optional value need to return nil
        builder.text = nil
        XCTAssertNil(builder.text)
    }

    struct StringCodingKey: CodingKey {
        let intValue: Int? = nil
        let stringValue: String

        init(_ str: String) {
            stringValue = str
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    func testCodingAccess() {
        let builder = Builder<MyStruct>()

        XCTAssertFalse(try builder.contains([StringCodingKey("text")]))
        XCTAssertThrowsError(try builder.value(for: [StringCodingKey("text")]) as Int,
                             "value by CodingKey throw if nothing is set")

        builder.text = "Hello"
        XCTAssertTrue(try builder.contains([StringCodingKey("text")]))
        XCTAssertEqual(try builder.value(for: [StringCodingKey("text")]), "Hello")
    }

    func testCodingNilAccess() {
        let builder = Builder<MyStruct>()

        XCTAssertThrowsError(try builder.isNil([StringCodingKey("text")]))

        builder.text = nil
        XCTAssertNoThrow(try builder.isNil([StringCodingKey("text")]))
        XCTAssertTrue(try builder.isNil([StringCodingKey("text")]))
    }

    static var allTests = [
        ("testDirectProperties", testDirectProperties),
        ("testNestedProperties", testNestedProperties),
        ("testNilProperties", testNilProperties),
        ("testCodingAccess", testCodingAccess),
        ("testCodingNilAccess", testCodingNilAccess),
    ]
}
