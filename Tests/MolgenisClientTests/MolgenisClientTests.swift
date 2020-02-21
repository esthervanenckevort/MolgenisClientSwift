import XCTest
@testable import MolgenisClient

final class MolgenisClientTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MolgenisClient().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
