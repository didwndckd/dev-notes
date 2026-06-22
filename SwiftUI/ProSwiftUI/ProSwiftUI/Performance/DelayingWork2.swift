//
//  DelayingWork2.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI
internal import Combine

extension DelayingWork2 {
    class ViewModel: ObservableObject {
        private var refreshTask: Task<Void, Error>?
        var workCounter = 0

        func doWorkNow() {
            workCounter += 1
            print("Work done: \(workCounter)")
        }

        func scheduleWork() {
            refreshTask?.cancel()

            refreshTask = Task {
                try await Task.sleep(until: .now + .seconds(3), clock: .continuous)
                doWorkNow()
            }
        }
    }
}

struct DelayingWork2: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Button("Do Work Soon", action: viewModel.scheduleWork)
            Button("Do Work Now", action: viewModel.doWorkNow)
        }
    }
}

#Preview {
    DelayingWork2()
}
