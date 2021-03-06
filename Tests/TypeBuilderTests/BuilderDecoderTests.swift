import XCTest
@testable import TypeBuilder

final class BuilderDecoderTests: XCTestCase {
    
    func testSimpleBuilding() {
        struct Struct: Codable, Reflectable {
            let string: String
            let int: Int
            let float: Float
            let bool: Bool
            let optional: String?
        }
        let builder = Builder<Struct>()
        builder.string = "String"
        builder.int = 42
        builder.float = 3.14
        builder.bool = true
        builder.optional = "Optional"

        var obj: Struct!
        XCTAssertNoThrow(obj = try builder.build())
        XCTAssertEqual(obj.string, "String")
        XCTAssertEqual(obj.int, 42)
        XCTAssertEqual(obj.float, 3.14)
        XCTAssertEqual(obj.bool, true)
        XCTAssertEqual(obj.optional, "Optional")

        builder.optional = nil
        XCTAssertNoThrow(obj = try builder.build())
        XCTAssertNil(obj.optional)
    }

    func testNestedObjects() {
        struct Nested: Codable, Reflectable {
            let int: Int
        }
        struct Struct: Codable, Reflectable {
            let string: String
            let nested: Nested
        }

        let builder = Builder<Struct>()
        builder.string = "String"
        builder.nested.int = 42

        let obj = try! builder.build()
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj.string, "String")
        XCTAssertEqual(obj.nested.int, 42)
    }

    static var allTests = [
        ("testSimpleBuilding", testSimpleBuilding),
        ("testNestedObjects", testNestedObjects)
    ]
}
