//
//  SkippingWork2.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI

struct OnFirstAppearModifier: ViewModifier {
    @State private var hasLoaded = false
    var perform: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            guard hasLoaded == false else { return }
            hasLoaded = true
            perform()
        }
    }
}

extension View {
    func onFirstAppear(perform: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(perform: perform))
    }
}

struct SkippingWork2: View {
    var body: some View {
        TabView {
            ForEach(1..<6) { i in
                ExampleView(number: i)
                    .tabItem { Label(String(i), systemImage: "\(i).circle") }
            }
        }
    }
}

extension SkippingWork2 {
    struct ExampleView: View {
        let number: Int

        var body: some View {
            Text("View \(number)")
//                .onAppear {
                .onFirstAppear {
                    print("View \(number) appearing")
                }
        }
    }
}

#Preview {
    SkippingWork2()
}
