import Darwin
import Foundation

fileprivate func trap(_ signal: Int32, action: @escaping @convention(c) (Int32) -> (Void)) {
    typealias SignalAction = sigaction
    var signalAction = SignalAction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
    let _ = withUnsafePointer(to: &signalAction) { actionPointer in sigaction(signal, actionPointer, nil) }
}

@available(iOS 11.0, macOS 10.13, *)
class AssetServer {
    private static var process: Process?
    private static var retainCount = 0

    public static let PORT = 47792
    public static let PREFIX = "http://localhost:\(PORT)"
    public static let EMPTY_PAGE = "http://localhost:\(PORT)/empty.html"

    class func start () {
        retainCount += 1

        if retainCount == 1 {
            let python = URL(fileURLWithPath: "/usr/bin/python")
            let directory = URL(fileURLWithPath: "\(#file)").deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Assets", isDirectory: true)

            AssetServer.process = Process()
            AssetServer.process!.arguments = ["-m", "SimpleHTTPServer", "\(PORT)"]
            AssetServer.process!.currentDirectoryURL = directory
            AssetServer.process!.executableURL = python

            try! AssetServer.process!.run()

            // Catch aborting of the test and properly shut down the server
            trap(SIGINT) { _ in AssetServer.process?.terminate(); exit(EXIT_FAILURE) }

            // Give the python server som time to start
            usleep(330000)
        }
    }

    class func stop() {
        retainCount -= 1

        if retainCount == 0 {
            AssetServer.process!.terminate()

            // Remove previously registered trap
            Darwin.signal(SIGINT, SIG_DFL)
        }
    }

    class func url(forFile fileName: String) -> URL {
        return URL(string: "\(PREFIX)/\(fileName)")!
    }
}
