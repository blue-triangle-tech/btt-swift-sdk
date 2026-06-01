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

        // ── Resolve BTTInstrumentor binary ────────────────────────
        let binary: PluginContext.Tool
        do {
            binary = try context.tool(named: "BTTInstrumentor")
        } catch {
            Diagnostics.error("❌ BTTInstrumentor binary not found: \(error)")
            return
        }

        print("")
        print("╔══════════════════════════════════════════╗")
        print("║   BlueTriangle · BTT Inject              ║")
        print("╚══════════════════════════════════════════╝")
        print("")
        print("⚙️  Binary: \(binary.path.string)")
        print("")

        // ── Collect all Swift source files ───────────────────────
        var allFiles: [Path] = []

        for target in context.package.targets {
            guard let swiftTarget = target as? SwiftSourceModuleTarget else { continue }

            let swiftFiles = swiftTarget.sourceFiles
                .filter { $0.type == .source && $0.path.extension == "swift" }
                .map { $0.path }

            if swiftFiles.isEmpty { continue }

            print("📂 Target: \(target.name) (\(swiftFiles.count) Swift files)")
            allFiles.append(contentsOf: swiftFiles)
        }

        if allFiles.isEmpty {
            print("⚠️  No Swift source files found — nothing to inject")
            return
        }

        print("")
        print("🔧 Injecting @BTTTrackScreen...")
        print("")

        // ── Run BTTInstrumentor on each file ─────────────────────
        var injected = 0
        var skipped  = 0
        var failed   = 0

        for filePath in allFiles {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary.path.string)
            process.arguments = [filePath.string]

            // Capture output
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
                        let fileName = filePath.lastComponent
                        print("  ✅ \(fileName)")
                    }
                default:
                    failed += 1
                    let fileName = filePath.lastComponent
                    print("  ⚠️  Skipped: \(fileName)")
                }

            } catch {
                failed += 1
                Diagnostics.warning("Failed to process \(filePath.lastComponent): \(error.localizedDescription)")
            }
        }

        // ── Summary ───────────────────────────────────────────────
        print("")
        print("────────────────────────────────────────────")
        print("  Injected : \(injected)")
        print("  Skipped  : \(skipped) (already annotated)")
        print("  Failed   : \(failed)")
        print("────────────────────────────────────────────")

        if failed > 0 {
            Diagnostics.warning("⚠️  \(failed) file(s) could not be processed")
        } else {
            print("")
            print("✅ BTT injection complete")
        }

        print("")
    }
}
