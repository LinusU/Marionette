import Foundation
import JSBridge
import PromiseKit
import XCTest

import Marionette

@available(iOS 11.0, macOS 10.13, *)
class EvaluateTests: MarionetteTestCase {
    func test_evaluate_shouldWork() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("7 * 3") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 21)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldThrowWhenEvaluationTriggersReload() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("(function () { location.reload(); return new Promise(resolve => setTimeout(resolve, 10)) }())") as Promise<Void>
            }.done {
                XCTFail("Missed expected error")
            }.recover { (err) throws -> Promise<Void> in
                guard err is AbortedError else { throw err }
                return Promise.value(())
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldAwaitPromise() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("Promise.resolve(8 * 7)") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 56)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldRejectPromiseWithException() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("not.existing.object.property") as Promise<Void>
            }.done {
                XCTFail("Missed expected error")
            }.recover { (err) throws -> Promise<Void> in
                guard let e = err as? JSError else { throw err }

                XCTAssertNotNil(e.message.range(of: "Can't find variable: not"))

                return Promise.value(())
            }
        }

        waitForExpectations(timeout: 5)
    }

    func skipped_test_evaluate_shouldSupportThrownStringsAsErrorMessages() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("(function () { throw 'qwerty' }())") as Promise<Void>
            }.done {
                XCTFail("Missed expected error")
            }.recover { (err) throws -> Promise<Void> in
                guard let e = err as? JSError else { throw err }

                XCTAssertNotNil(e.message.range(of: "qwerty"))

                return Promise.value(())
            }
        }

        waitForExpectations(timeout: 5)
    }

    func skipped_test_evaluate_shouldSupportThrownNumbersAsErrorMessages() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("(function () { throw 100500 }())") as Promise<Void>
            }.done {
                XCTFail("Missed expected error")
            }.recover { (err) throws -> Promise<Void> in
                guard let e = err as? JSError else { throw err }

                XCTAssertNotNil(e.message.range(of: "100500"))

                return Promise.value(())
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldReturnComplexObjects() {
        let page = Marionette()

        struct TestResult: Decodable, Equatable {
            let foo: String
        }

        expectation() {
            firstly {
                page.evaluate("{foo: 'bar!'}") as Promise<TestResult>
            }.done {
                XCTAssertEqual($0, TestResult(foo: "bar!"))
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldAcceptAString() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("1 + 2") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 3)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldAcceptAStringWithSemiColons() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("1 + 5;") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 6)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_evaluate_shouldAcceptAStringWithComments() {
        let page = Marionette()

        expectation() {
            firstly {
                page.evaluate("2 + 5;\n// do some math!") as Promise<Double>
            }.done {
                XCTAssertEqual($0, 7)
            }
        }

        waitForExpectations(timeout: 5)
    }
}
