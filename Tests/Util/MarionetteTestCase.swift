import PromiseKit
import XCTest

@available(iOS 11.0, macOS 10.13, *)
class MarionetteTestCase: XCTestCase {
    override class func setUp() {
        super.setUp()
        AssetServer.start()
    }

    override class func tearDown() {
        AssetServer.stop()
        super.tearDown()
    }

    func expectation(description: String? = nil, _ promiseFactory: () -> Promise<Void>) {
        let done = self.expectation(description: "Promise\(description.map({" \($0) "}) ?? " ")settled")

        firstly {
            promiseFactory()
        }.catch { err in
            XCTFail("Failed with error: \(err)")
        }.finally {
            done.fulfill()
        }
    }
}
