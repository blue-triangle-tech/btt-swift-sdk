//
//  BTTInstrumentorPlugin.swift
//  blue-triangle
//
//  Created by Ashok Singh on 01/06/26.
//

import PackagePlugin
import Foundation

@main
struct BTTInstrumentorPlugin: CommandPlugin {

    func performCommand(context: PluginContext, arguments: [String]) throws {

        // Resolve binary
        let binary = try context.tool(named: "BTTInstrumentor")

        print("")
        print("╔══════════════════════════════════════════╗")
        print("║   BlueTriangle · BTT Inject              ║")
        print("╚══════════════════════════════════════════╝")
        print("")

        // Get source root from arguments or current directory
        var targetPath = FileManager.default.currentDirectoryPath
        if let idx = arguments.firstIndex(of: "--target-path"), arguments.count > idx + 1 {
            targetPath = arguments[idx + 1]
        }

        print("📂 Source root: \(targetPath)")
        print("⚙️  Binary: \(binary.path.string)")
        print("")

        // Find all Swift files in target path
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: targetPath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("❌ Could not enumerate \(targetPath)")
            return
        }

        var swiftFiles: [String] = []
        for case let url as URL in enumerator {
            let path = url.path
            guard path.hasSuffix(".swift") else { continue }
            guard !path.contains("/Pods/") else { continue }
            guard !path.contains("/.build/") else { continue }
            guard !path.contains("/DerivedData/") else { continue }
            guard !path.contains("/BTTInstrumentor/") else { continue }
            swiftFiles.append(path)
        }

        if swiftFiles.isEmpty {
            print("⚠️  No Swift files found in \(targetPath)")
            return
        }

        print("🔧 Injecting @BTTTrackScreen into \(swiftFiles.count) files...")
        print("")

        // Run BTTInstrumentor on each file
        var injected = 0
        var skipped  = 0
        var failed   = 0

        for filePath in swiftFiles {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary.path.string)
            process.arguments = [filePath]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError  = stderrPipe

            do {
                try process.run()
                process.waitUntilExit()

                let output = String(
                    data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                ) ?? ""

                switch process.terminationStatus {
                case 0:
                    if output.contains("skipped") || output.contains("already") {
                        skipped += 1
                    } else {
                        injected += 1
                        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                        print("  ✅ \(fileName)")
                    }
                default:
                    failed += 1
                    let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                    print("  ⚠️  Skipped: \(fileName)")
                }
            } catch {
                failed += 1
                Diagnostics.warning("Failed: \(filePath): \(error.localizedDescription)")
            }
        }

        // Summary
        print("")
        print("────────────────────────────────────────────")
        print("  Injected : \(injected)")
        print("  Skipped  : \(skipped) (already annotated)")
        print("  Failed   : \(failed)")
        print("────────────────────────────────────────────")
        print("")
        print("✅ BTT injection complete")
        print("")
    }
}
