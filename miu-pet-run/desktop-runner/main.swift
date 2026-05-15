import AppKit
import Foundation

func resolveAssetRoot() -> URL {
    let args = CommandLine.arguments
    if let index = args.firstIndex(of: "--asset-root"), index + 1 < args.count {
        return URL(fileURLWithPath: args[index + 1], isDirectory: true)
    }
    if let resources = Bundle.main.resourceURL {
        let bundledFrames = resources.appendingPathComponent("frames", isDirectory: true)
        if FileManager.default.fileExists(atPath: bundledFrames.path) {
            return bundledFrames
        }
    }
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    return cwd.appendingPathComponent("miu-pet-run/phase1-actions/frames", isDirectory: true)
}

let app = NSApplication.shared
let config = RunnerConfig(assetRoot: resolveAssetRoot())
let delegate = MiuRunner(config: config)
app.delegate = delegate
app.run()
