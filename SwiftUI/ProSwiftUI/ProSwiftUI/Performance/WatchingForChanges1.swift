//
//  WatchingForChanges1.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI
internal import Combine

class AutorefreshingObject: ObservableObject {
    var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

struct WatchingForChanges1: View {
    @StateObject private var viewModel = AutorefreshingObject()

    var body: some View {
        Text("Example View Here")
            .background(.random)
    }
}

#Preview {
    WatchingForChanges1()
}
