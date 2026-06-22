//
//  AppCycleTest.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI

//@main
struct TestApp: App {
    @State private var property = ExampleProperty(location: "App")

    var body: some Scene {
        print("In App.body")

        return WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }

    init() {
        print("In App.init")
    }
}

extension TestApp {
    struct ExampleProperty {
        init(location: String) {
            print("Creating ExampleProperty from \(location)")
        }
    }
    
    struct ExampleModifier: ViewModifier {
        init(location: String) {
            print("Creating ExampleModifier from \(location)")
        }
        
        func body(content: Content) -> some View {
            print("In ExampleModifier.body()")
            return content
        }
    }
    
    struct ContentView: View {
        @State private var property = ExampleProperty(location: "ContentView")
        
        var body: some View {
            print("In ContentView.body")
            
            return NavigationLink("Hello, world!") {
                DetailView()
            }
            .modifier(ExampleModifier(location: "ContentView"))
            .task { print("In first task") }
            .task { print("In second task") }
            .onAppear { print("In first onAppear") }
            .onAppear { print("In second onAppear") }
        }
        
        init() {
            print("In ContentView.init")
        }
    }
    
    struct DetailView: View {
        @State private var property = ExampleProperty(location: "DetailView")
        
        var body: some View {
            print("In DetailView.body")
            
            return Text("Hello, world!")
                .modifier(ExampleModifier(location: "DetailView"))
                .task { print("In detail task") }
                .onAppear { print("In detail onAppear") }
        }
        
        init() {
            print("In DetailView.init")
        }
    }
}
