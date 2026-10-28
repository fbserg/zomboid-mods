import AppKit
import CoreGraphics
import Foundation

let owned = Set(CommandLine.arguments.dropFirst().map { Int32($0)! })
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
let visible = windows.compactMap { $0[kCGWindowOwnerPID as String] as? Int32 }.filter { owned.contains($0) }
let front = NSWorkspace.shared.frontmostApplication?.processIdentifier
if !visible.isEmpty || (front != nil && owned.contains(front!)) {
    fputs("PZ_TEST_FAIL OS-visible or foreground game process: \(visible)\n", stderr)
    exit(1)
}
