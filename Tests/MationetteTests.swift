import XCTest

import Foundation
import PromiseKit

@testable import Marionette

extension XCTestCase {
    func expectation(description: String, _ promiseFactory: () -> Promise<Void>) {
        let done = self.expectation(description: "Promise \(description) settled")

        firstly {
            promiseFactory()
        }.catch { err in
            XCTFail("Failed with error: \(err)")
        }.finally {
            done.fulfill()
        }
    }
}

@available(iOS 11.0, macOS 10.13, *)
class MarionetteTests: XCTestCase {
    func testSearchGoogle() {
        let page = Marionette()

        self.expectation(description: "searchGoogle") {
            firstly {
                page.goto(URL(string: "https://www.google.com/")!)
            }.then {
                page.type("input[name='q']", "LinusU Marionette")
            }.then {
                when(fulfilled: page.waitForNavigation(), page.click("input[type='submit']"))
            }.then {
                page.screenshot()
            }.done {
                XCTAssertEqual($0.size.width, 1024)
                XCTAssertEqual($0.size.height, 768)
            }
        }

        self.waitForExpectations(timeout: 30)
    }

    func testMultipleNavigations() {
        let page = Marionette()

        self.expectation(description: "multipleNavigations") {
            firstly {
                return page.goto(URL(string: "https://www.google.com/")!)
            }.then {
                page.goto(URL(string: "https://www.example.com/")!)
            }.then {
                page.goto(URL(string: "https://www.snowsli.de/")!)
            }.then {
                page.goto(URL(string: "https://www.example.com/")!)
            }
        }

        self.waitForExpectations(timeout: 30)
    }
}
