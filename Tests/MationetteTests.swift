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

    func testEvaluate() {
        let page = Marionette()

        struct TestResult: Decodable, Equatable {
            let a: String
            let b: Double
            let c: [Bool]
        }

        self.expectation(description: "evaluate") {
            firstly {
                return page.goto(URL(string: "https://www.example.com/")!)
            }.then {
                page.evaluate("1 + 2") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 3.0)
            }.then {
                page.evaluate("1 + 5;") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 6.0)
            }.then {
                page.evaluate("1 + 5;\n// do some math!") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 6.0)
            }.then {
                page.evaluate("{a:'test',b:4.2,c:[true,false]}") as Promise<TestResult>
            }.done {
                XCTAssertEqual($0, TestResult(a: "test", b: 4.2, c: [true, false]))
            }.then {
                page.evaluate("a = 3, a + 2") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 5.0)
            }
        }

        self.waitForExpectations(timeout: 30)
    }

    func testWaitForFunctionDuringNavigation() {
        let page = Marionette()
        var result: Promise<Void>?

        self.expectation(description: "waitForFunctionDuringNavigation") {
            firstly {
                page.goto(URL(string: "https://www.example.com/")!)
            }.then { _ -> Promise<Void> in
                result = page.waitForFunction("window.location.origin === 'https://www.example.org'")

                return after(.milliseconds(240)).then {
                    page.goto(URL(string: "https://www.example.org/")!)
                }
            }.then {
                result!
            }
        }

        self.waitForExpectations(timeout: 10)
    }

    func testWaitForSelectorDuringNavigation() {
        let page = Marionette()
        var result: Promise<Void>?

        self.expectation(description: "waitForSelectorDuringNavigation") {
            firstly {
                page.goto(URL(string: "https://www.example.com/")!)
            }.then { _ -> Promise<Void> in
                result = page.waitForSelector("body.env-production")

                return after(.milliseconds(240)).then {
                    page.goto(URL(string: "https://www.github.com/")!)
                }
            }.then {
                result!
            }
        }

        self.waitForExpectations(timeout: 10)
    }
}
