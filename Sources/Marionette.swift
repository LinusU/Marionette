import Foundation
import JSBridge
import PromiseKit
import Signals
import WebKit

#if canImport(Cocoa)
import Cocoa
#endif

#if canImport(UIKit)
import UIKit
#endif

let HELPER_CODE = """
const nativeInputValueGetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').get
const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set
const nativeTextAreaValueGetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').get
const nativeTextAreaValueSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set

/* Native requestAnimationFrame doesn't work headless */
window['requestAnimationFrame'] = (function () {
    let last = 0
    let queue = []

    const frameDuration = 1000 / 60

    function rethrow (err) {
        throw err
    }

    function processQueue () {
        const batch = queue

        queue = []

        for (const fn of batch) {
            try {
                fn()
            } catch (err) {
                setTimeout(rethrow, 0, err)
            }
        }
    }

    return function requestAnimationFrame (fn) {
        if (queue.length === 0) {
            const now = performance.now()
            const next = Math.max(0, frameDuration - (now - last))

            last = (next + now)

            setTimeout(processQueue, Math.round(next))
        }

        queue.push(fn)
    }
}())

class TimeoutError extends Error {
    constructor (message) {
        super(message)
        this.name = 'TimeoutError'
    }
}

function sleep (ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

function idle (min, max) {
    return sleep(Math.floor(min + (Math.random() * (max - min))))
}

window['SwiftMarionetteReload'] = function () {
    window.location.reload()
}

window['SwiftMarionetteSetContent'] = function (html) {
    document.open()
    document.write(html)
    document.close()
}

window['SwiftMarionetteSimulateClick'] = async function (selector) {
    const target = document.querySelector(selector)

    target.click()
}

window['SwiftMarionetteSimulateType'] = async function (selector, text) {
    const target = document.querySelector(selector)
    const getter = (target.tagName === 'TEXTAREA') ? nativeTextAreaValueGetter : nativeInputValueGetter
    const setter = (target.tagName === 'TEXTAREA') ? nativeTextAreaValueSetter : nativeInputValueSetter

    target.focus()
    await idle(50, 90)

    let currentValue = getter.call(target)
    for (const char of text) {
        const down = new KeyboardEvent('keydown', { key: char, charCode: char.charCodeAt(0), keyCode: char.charCodeAt(0), which: char.charCodeAt(0) })
        target.dispatchEvent(down)

        const press = new KeyboardEvent('keypress', { key: char, charCode: char.charCodeAt(0), keyCode: char.charCodeAt(0), which: char.charCodeAt(0) })
        target.dispatchEvent(press)

        const ev = new InputEvent('input', { data: char, inputType: 'insertText', composed: true, bubbles: true })
        currentValue += char
        setter.call(target, currentValue)
        target.dispatchEvent(ev)

        await idle(20, 110)

        const up = new KeyboardEvent('keyup', { key: char, charCode: char.charCodeAt(0), keyCode: char.charCodeAt(0), which: char.charCodeAt(0) })
        target.dispatchEvent(up)

        await idle(15, 120)
    }

    const ev = new Event('change', { bubbles: true })
    target.dispatchEvent(ev)

    target.blur()
}

window['SwiftMarionetteWaitForFunction'] = function (fn) {
    return new Promise((resolve, reject) => {
        let timedOut = false

        function onRaf () {
            if (timedOut) return
            if (fn()) return resolve()
            requestAnimationFrame(onRaf)
        }

        setTimeout(() => {
            timedOut = true
            reject(new TimeoutError(`Timeout reached waiting for function to return truthy`))
        }, 30000)

        onRaf()
    })
}

window['SwiftMarionetteWaitForSelector'] = function (selector) {
    if (document.querySelector(selector)) return Promise.resolve()

    return new Promise((resolve, reject) => {
        const observer = new MutationObserver((mutations) => {
            if (document.querySelector(selector)) {
                observer.disconnect()
                resolve()
            }
        })

        setTimeout(() => {
            observer.disconnect()
            reject(new TimeoutError(`Timeout reached waiting for "${selector}" to appear`))
        }, 30000)

        observer.observe(document, {
            childList: true,
            subtree: true,
            attributes: true
        })
    })
}
"""

@available(iOS 11.0, macOS 10.13, *)
open class Marionette: NSObject, WKNavigationDelegate {
    public let bridge: JSBridge
    public let webView: WKWebView

    private let onNavigationFinished = Signal<WKNavigation>()

    public override init() {
        bridge = JSBridge(libraryCode: HELPER_CODE, headless: false, incognito: true)
        webView = bridge.webView!

        super.init()

        webView.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3624.0 Safari/537.36"
    }

    @objc
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.onNavigationFinished.fire(navigation)
    }

    /** Public API **/

    public func click(_ selector: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteSimulateClick", withArg: selector) as Promise<Void>
    }

    public func evaluate(_ script: String) -> Promise<Void> {
        return bridge.call(function: "() => { return \(script)\n }")
    }

    public func evaluate<Result: Decodable>(_ script: String) -> Promise<Result> {
        return bridge.call(function: "() => { return \(script)\n }")
    }

    public func goto(_ url: URL) -> Promise<Void> {
        let promise = self.waitForNavigation()
        webView.load(URLRequest(url: url))
        return promise
    }

    public func setContent(_ html: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteSetContent", withArg: html) as Promise<Void>
    }

    public func type(_ selector: String, _ text: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteSimulateType", withArgs: (selector, text)) as Promise<Void>
    }

    public func reload() -> Promise<Void> {
        return when(fulfilled: waitForNavigation(), bridge.call(function: "SwiftMarionetteReload") as Promise<Void>)
    }

    public func waitForFunction(_ fn: String) -> Promise<Void> {
        return firstly {
            self.bridge.call(function: "() => SwiftMarionetteWaitForFunction(() => { return \(fn)\n })") as Promise<Void>
        }.recover { (err) -> Promise<Void> in
            if err is AbortedError { return self.waitForFunction(fn) } else { throw err }
        }
    }

    public func waitForNavigation() -> Promise<Void> {
        return Promise { seal in self.onNavigationFinished.subscribeOnce(with: self) { _ in seal.fulfill(()) } }
    }

    public func waitForSelector(_ selector: String) -> Promise<Void> {
        return firstly {
            self.bridge.call(function: "SwiftMarionetteWaitForSelector", withArg: selector) as Promise<Void>
        }.recover { (err) -> Promise<Void> in
            if err is AbortedError { return self.waitForSelector(selector) } else { throw err }
        }
    }

    #if canImport(Cocoa)
    public func screenshot() -> Promise<NSImage> {
        return Promise { seal in self.webView.takeSnapshot(with: nil, completionHandler: seal.resolve) }
    }
    #endif

    #if canImport(UIKit)
    public func screenshot() -> Promise<UIImage> {
        return Promise { seal in self.webView.takeSnapshot(with: nil, completionHandler: seal.resolve) }
    }
    #endif
}
