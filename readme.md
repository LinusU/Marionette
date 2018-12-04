# Marionette

Marionette is a Swift library which provides a high-level API to control a WKWebView.

The goal is to have the API closely mirror that of [Puppeteer](https://github.com/GoogleChrome/puppeteer).

## Installation

### SwiftPM

```swift
dependencies: [
    .package(url: "https://github.com/LinusU/Marionette", from: "1.0.0"),
]
```

### Carthage

```text
github "LinusU/Marionette" ~> 1.0.0
```

## Usage

```swift
let page = Marionette()

firstly {
    page.goto(URL(string: "https://www.google.com/")!)
}.then {
    page.type("input[name='q']", "LinusU Marionette")
}.then {
    when(fulfilled: page.waitForNavigation(), page.click("input[type='submit']"))
}.then {
    page.screenshot()
}.done {
    print("Screenshot of Google results: \($0)")
}
```

## Hacking

The Xcode project is generated automatically from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). It's only checked in because Carthage needs it, do not edit it manually.

```sh
$ mint run yonaskolb/xcodegen
💾  Saved project to Marionette.xcodeproj
```
