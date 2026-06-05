//
//  BTTNavigationTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 05/06/26.
//

import SwiftUI
import Combine

@MainActor
public final class BTTNavigationTracker<Value: Hashable>: ObservableObject {

    @Published public var path: [Value] = []
    public var screenName: ((Value) -> String)?

    private var lastPath: [Value] = []
    private var cancellables = Set<AnyCancellable>()

    public init(screenName: ((Value) -> String)? = nil) {
        self.screenName = screenName
        $path
            .dropFirst()
            .sink { [weak self] in self?.handleChange($0) }
            .store(in: &cancellables)
    }

    private func handleChange(_ newPath: [Value]) {
        defer { lastPath = newPath }
        guard newPath.count != lastPath.count else { return }

        if newPath.count > lastPath.count {
            if let pushed = newPath.last {
                track(name(for: pushed))
            }
        } else {
            if let current = newPath.last {
                track(name(for: current))
            } else {
                track("Root")
            }
        }
    }

    private func name(for value: Value) -> String {
        screenName?(value) ?? String(describing: value)
    }

    private func track(_ screenName: String) {
        print("[BTT] Screen:", screenName)
        let sceenTracker = BTTScreenTracker(screenName)
        sceenTracker.loadStarted()
        sceenTracker.loadEnded()
        sceenTracker.viewStart()
        sceenTracker.viewingEnd()
    }
}
