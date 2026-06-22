//
//  WatchingForChanges2.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI
internal import Combine

extension WatchingForChanges2 {
    class AutorefreshingObject: ObservableObject {
        var timer: Timer?
    
        init() {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.objectWillChange.send()
            }
        }
    }
}

struct WatchingForChanges2: View {
    @StateObject private var viewModel = AutorefreshingObject()
    
    var body: some View {
        let _ = Self._printChanges()
        Text("Example View Here")
    }
}

#Preview {
    WatchingForChanges2()
}
