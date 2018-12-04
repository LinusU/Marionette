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
class TimeoutError extends Error {
    constructor (message) {
        super(message)
        this.name = 'TimeoutError'
    }
}

function sleep (ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

function idle () {
    return sleep(Math.ceil(Math.random() * 80))
}

async function waitFor (fn, description) {
    if (fn()) return

    for (let i = 0; i < 30; i++) {
        await sleep(1000)
        if (fn()) return
    }

    throw new TimeoutError(`Timeout reached waiting for ${description}`)
}

window['SwiftMarionetteSimulateClick'] = async function (selector) {
    const target = document.querySelector(selector)

    target.focus()
    await idle()
    target.click()
}

window['SwiftMarionetteSimulateType'] = async function (selector, text) {
    const target = document.querySelector(selector)

    target.focus()
    await idle()

    for (const char of text) {
        const ev = new InputEvent('input', { data: char, inputType: 'insertText', composed: true, bubbles: true })
        target.value += char
        target.dispatchEvent(ev)
        await idle()
    }

    const ev = new Event('change', { bubbles: true })
    target.dispatchEvent(ev)

    target.blur()
}

window['SwiftMarionetteWaitForFunction'] = async function (fn) {
    return waitFor(new Function('...args', 'return ' + fn), 'function to return truthy')
}

window['SwiftMarionetteWaitForSelector'] = async function (selector) {
    return waitFor(() => document.querySelector(selector), `"${selector}" to appear`)
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.onNavigationFinished.fire(navigation)
    }

    /** Public API **/

    public func click(_ selector: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteSimulateClick", withArg: selector) as Promise<Void>
    }

    public func evaluate(_ script: String) -> Promise<Void> {
        return Promise { seal in webView.evaluateJavaScript(script) { (_, err) in seal.resolve(err) } }
    }

    public func goto(_ url: URL) -> Promise<Void> {
        let promise = self.waitForNavigation()
        webView.load(URLRequest(url: url))
        return promise
    }

    public func type(_ selector: String, _ text: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteSimulateType", withArgs: (selector, text)) as Promise<Void>
    }

    public func waitForFunction(_ fn: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteWaitForFunction", withArg: fn) as Promise<Void>
    }

    public func waitForNavigation() -> Promise<Void> {
        return Promise { seal in self.onNavigationFinished.subscribeOnce(with: self) { _ in seal.fulfill(()) } }
    }

    public func waitForSelector(_ selector: String) -> Promise<Void> {
        return self.bridge.call(function: "SwiftMarionetteWaitForSelector", withArg: selector) as Promise<Void>
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
