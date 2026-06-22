//
//  SkippingWork3.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI

public extension View {
    func watchOS<Content: View>(_ modifier: @escaping (Self) -> Content) -> some View {
        #if os(watchOS)
        modifier(self)
        #else
        self
        #endif
    }
}

struct SkippingWork3: View {
    var body: some View {
        Text("Hello, world!")
            .watchOS {
                $0.padding(0)
            }
    }
}

#Preview {
    SkippingWork3()
}
