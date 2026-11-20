import AppKit

extension NSApplication {
    public func relaunch() {
        let reopen = Process()
        reopen.executableURL = URL(fileURLWithPath: "/bin/sh")
        // open only activates a copy that's still running, so wait for this one to quit first.
        reopen.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        try? reopen.run()
        terminate(nil)
    }
}
