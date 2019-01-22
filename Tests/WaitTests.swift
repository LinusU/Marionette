import Foundation
import JSBridge
import PromiseKit
import XCTest

import Marionette

@available(iOS 11.0, macOS 10.13, *)
class WaitTests: MarionetteTestCase {
    func test_waitForFunction_shouldAcceptAString() {
        let page = Marionette()
        let watchdog = page.waitForFunction("window.__FOO === 1")

        expectation() {
            firstly {
                page.evaluate("window.__FOO = 1")
            }.then {
                watchdog
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForFunction_shouldSurviveCrossProcessNavigation() {
        let page = Marionette()

        var fooFound = false
        let waitForSelector = page.waitForFunction("window.__FOO === 1").done { _ in fooFound = true }

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.done {
                XCTAssertEqual(fooFound, false)
            }.then {
                page.reload()
            }.done {
                XCTAssertEqual(fooFound, false)
            }.then {
                page.goto(AssetServer.url(forFile: "grid.html"))
            }.done {
                XCTAssertEqual(fooFound, false)
            }.then {
                page.evaluate("window.__FOO = 1")
            }.then {
                waitForSelector
            }.done {
                XCTAssertEqual(fooFound, true)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldImmediatelyResolvePromiseIfNodeExists() {
        let page = Marionette()

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.then {
                page.waitForSelector("*")
            }.then {
                page.evaluate("document.body.appendChild(document.createElement('div'))")
            }.then {
                page.waitForSelector("div")
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldResolvePromiseWhenNodeIsAdded() {
        let page = Marionette()
        let watchdog = page.waitForSelector("div")

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.then {
                page.evaluate("document.body.appendChild(document.createElement('br'))")
            }.then {
                page.evaluate("document.body.appendChild(document.createElement('div'))")
            }.then {
                watchdog
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldWorkWhenNodeIsAddedThroughInnerHtml() {
        let page = Marionette()
        let watchdog = page.waitForSelector("h3 div")

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.then {
                page.evaluate("document.body.appendChild(document.createElement('span'))")
            }.then {
                page.evaluate("document.querySelector('span').innerHTML = '<h3><div></div></h3>'")
            }.then {
                watchdog
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldThrowIfEvaluationFailed() {
        let page = Marionette()

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.then {
                page.evaluate("document.querySelector = null")
            }.then {
                page.waitForSelector("*")
            }.done {
                XCTFail("Missed expected error")
            }.recover { (err) throws -> Promise<Void> in
                guard let e = err as? JSError else { throw err }

                XCTAssertNotNil(e.message.range(of: "document.querySelector is not a function"))

                return Promise.value(())
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldSurviveCrossProcessNavigation() {
        let page = Marionette()

        var boxFound = false
        let waitForSelector = page.waitForSelector(".box").done { _ in boxFound = true }

        expectation() {
            firstly {
                page.goto(AssetServer.url(forFile: "empty.html"))
            }.done {
                XCTAssertEqual(boxFound, false)
            }.then {
                page.reload()
            }.done {
                XCTAssertEqual(boxFound, false)
            }.then {
                page.goto(AssetServer.url(forFile: "grid.html"))
            }.then {
                waitForSelector
            }.done {
                XCTAssertEqual(boxFound, true)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_waitForSelector_shouldRespondToNodeAttributeMutation() {
        let page = Marionette()

        var divFound = false
        let waitForSelector = page.waitForSelector(".zombo").done { _ in divFound = true }

        expectation() {
            firstly {
                page.setContent("<div class='notZombo'></div>")
            }.done {
                XCTAssertEqual(divFound, false)
            }.then {
                page.evaluate("document.querySelector('div').className = 'zombo'")
            }.then {
                waitForSelector
            }.done {
                XCTAssertEqual(divFound, true)
            }
        }

        waitForExpectations(timeout: 5)
    }
}
